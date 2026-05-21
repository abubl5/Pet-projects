// Пакет handler содержит HTTP-обработчики.
//
// Взаимодействие с бизнес-логикой осуществляется через интерфейс.
// Определите этот интерфейс здесь, по месту использования.
// Реализуйте все обработчики самостоятельно.
package handler

import (
	"context"
	"encoding/json"
	"errors"
	"gopherledger/internal/domain"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

type Service interface {
	RegisterUser(login, password string) (string, error)
	LoginUser(login, password string) (string, error)
	CreateOrder(userID int64, number string) (*domain.Order, error)
	GetUserOrders(userID int64) ([]domain.Order, error)
	GetAllUsers() ([]domain.User, error)
	GetAllOrders() ([]domain.Order, error)
	GetBalance(userID int64) (domain.Balance, error)
	Withdraw(userID int64, orderNumber string, sum float64) error
	GetWithdrawals(userID int64) ([]domain.Withdrawal, error)
	GetAllWithdrawals() ([]domain.Withdrawal, error)
}

type authRequest struct {
	Login    string `json:"login"`
	Password string `json:"password"`
}

type errorResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type withdrawRequest struct {
	Order string  `json:"order"`
	Sum   float64 `json:"sum"`
}

type orderResponse struct {
	Number     string    `json:"number"`
	Status     string    `json:"status"`
	Accrual    *float64  `json:"accrual,omitempty"`
	UploadedAt time.Time `json:"uploaded_at"`
}

type balanceResponse struct {
	Current   float64 `json:"current"`
	Withdrawn float64 `json:"withdrawn"`
}

type withdrawalResponse struct {
	Order       string    `json:"order"`
	Sum         float64   `json:"sum"`
	ProcessedAt time.Time `json:"processed_at"`
}

// Handler хранит зависимость от бизнес-логики.
// Замените interface{} на свой интерфейс.
type Handler struct {
	svc Service
}

// New создаёт Handler.
func New(svc Service) *Handler {
	return &Handler{svc: svc}
}

// ---------------------------------------------------------------------------
// Вспомогательные функции для ответов - предоставлены
// ---------------------------------------------------------------------------

// writeError записывает JSON-ответ с ошибкой.
// Клиент видит только userMsg. Внутренние детали пишутся только в лог.
// Прочитайте ТЗ и создайте структуру тела ответа самостоятельно.

func writeError(w http.ResponseWriter, status int, code, userMsg string, internalErr error) {
	if internalErr != nil {
		log.Printf("ошибка code=%s status=%d: %v", code, status, internalErr)
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	resp := errorResponse{
		Code:    code,
		Message: userMsg,
	}

	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.Printf("writeError: %v", err)
	}
}

// writeJSON записывает успешный JSON-ответ.
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("writeJSON: %v", err)
	}
}

// ---------------------------------------------------------------------------
// Обработчики - реализуйте самостоятельно
// ---------------------------------------------------------------------------

// Register обрабатывает POST /api/user/register.
// При успехе: 200 OK, заголовок Authorization с токеном.
// При дублировании логина: 409 Conflict.
// При некорректных данных: 400 Bad Request.
func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "BAD_REQUEST", "Некорректное тело запроса", err)
		return
	}

	if req.Login == "" || req.Password == "" {
		writeError(w, http.StatusUnauthorized, "INVALID_CREDENTIALS", "Неверный логин или пароль", nil)
		return
	}

	token, err := h.svc.RegisterUser(req.Login, req.Password)
	if err != nil {
		if errors.Is(err, domain.ErrUserExists) {
			writeError(w, http.StatusConflict, "USER_EXISTS", "Пользователь уже существует", err)
			return
		}
		writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
		return
	}

	w.Header().Set("Authorization", token)
	w.WriteHeader(http.StatusOK)
}

// Login обрабатывает POST /api/user/login.
// При успехе: 200 OK, заголовок Authorization с токеном.
// При неверных данных: 401 Unauthorized.
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "BAD_REQUEST", "Некорректное тело запроса", err)
		return
	}

	if req.Login == "" || req.Password == "" {
		writeError(w, http.StatusBadRequest, "BAD_REQUEST", "Логин и пароль обязательны", nil)
		return
	}

	token, err := h.svc.LoginUser(req.Login, req.Password)
	if err != nil {
		if errors.Is(err, domain.ErrUserNotFound) || errors.Is(err, domain.ErrInvalidPassword) {
			writeError(w, http.StatusUnauthorized, "INVALID_CREDENTIALS", "Неверный логин или пароль", err)
			return
		}
		writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
		return
	}

	w.Header().Set("Authorization", token)
	w.WriteHeader(http.StatusOK)
}

// CreateOrder обрабатывает POST /api/user/orders.
// Тело запроса: номер заказа в виде обычного текста.
// 202 Accepted  - новый заказ принят в обработку.
// 200 OK        - заказ уже загружен этим пользователем.
// 409 Conflict  - заказ принадлежит другому пользователю.
// 422 Unprocessable Entity - номер не прошёл проверку Луна.
func (h *Handler) CreateOrder(w http.ResponseWriter, r *http.Request) {
	userID, ok := UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Требуется авторизация", nil)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		writeError(w, http.StatusBadRequest, "BAD_REQUEST", "Не удалось прочитать тело запроса", err)
		return
	}

	number := strings.TrimSpace(string(body))
	if number == "" {
		writeError(w, http.StatusBadRequest, "BAD_REQUEST", "Номер заказа обязателен", nil)
		return
	}

	_, err = h.svc.CreateOrder(userID, number)
	if err != nil {
		switch {
		case errors.Is(err, domain.ErrOrderOwnedByUser):
			w.WriteHeader(http.StatusOK)
			return
		case errors.Is(err, domain.ErrOrderExists):
			writeError(w, http.StatusConflict, "ORDER_EXISTS", "Заказ уже загружен другим пользователем", err)
			return
		case errors.Is(err, domain.ErrInvalidOrder):
			writeError(w, http.StatusUnprocessableEntity, "INVALID_ORDER", "Неверный номер заказа", err)
			return
		default:
			writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
			return
		}
	}

	w.WriteHeader(http.StatusAccepted)
}

// GetOrders обрабатывает GET /api/user/orders.
// 200 OK с JSON-массивом заказов или 204 No Content если заказов нет.
func (h *Handler) GetOrders(w http.ResponseWriter, r *http.Request) {
	userID, ok := UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Требуется авторизация", nil)
		return
	}

	orders, err := h.svc.GetUserOrders(userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
		return
	}

	if len(orders) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	response := make([]orderResponse, 0, len(orders))
	for _, order := range orders {
		item := orderResponse{
			Number:     order.Number,
			Status:     order.Status,
			UploadedAt: order.UploadedAt,
		}
		if order.Status == domain.OrderStatusProcessed {
			accrual := order.Accrual
			item.Accrual = &accrual
		}
		response = append(response, item)
	}

	writeJSON(w, http.StatusOK, response)
}

// GetBalance обрабатывает GET /api/user/balance.
func (h *Handler) GetBalance(w http.ResponseWriter, r *http.Request) {
	userID, ok := UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Требуется авторизация", nil)
		return
	}

	balance, err := h.svc.GetBalance(userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
		return
	}

	writeJSON(w, http.StatusOK, balanceResponse{
		Current:   balance.Current,
		Withdrawn: balance.Withdrawn,
	})
}

// Withdraw обрабатывает POST /api/user/balance/withdraw.
// 200 OK при успехе.
// 402 Payment Required при нехватке баллов.
// 422 Unprocessable Entity при неверном номере заказа.
func (h *Handler) Withdraw(w http.ResponseWriter, r *http.Request) {
	userID, ok := UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Требуется авторизация", nil)
		return
	}

	var req withdrawRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "BAD_REQUEST", "Некорректное тело запроса", err)
		return
	}

	if req.Order == "" || req.Sum <= 0 {
		writeError(w, http.StatusBadRequest, "BAD_REQUEST", "Неверные данные для списания", nil)
		return
	}

	err := h.svc.Withdraw(userID, req.Order, req.Sum)
	if err != nil {
		switch {
		case errors.Is(err, domain.ErrInsufficientFunds):
			writeError(w, http.StatusPaymentRequired, "INSUFFICIENT_FUNDS", "Недостаточно баллов", err)
			return
		case errors.Is(err, domain.ErrInvalidOrder):
			writeError(w, http.StatusUnprocessableEntity, "INVALID_ORDER", "Неверный номер заказа", err)
			return
		default:
			writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
			return
		}
	}

	w.WriteHeader(http.StatusOK)
}

// GetWithdrawals обрабатывает GET /api/user/withdrawals.
// 200 OK с массивом или 204 No Content если списаний нет.
func (h *Handler) GetWithdrawals(w http.ResponseWriter, r *http.Request) {
	userID, ok := UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Требуется авторизация", nil)
		return
	}

	withdrawals, err := h.svc.GetWithdrawals(userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
		return
	}

	if len(withdrawals) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	response := make([]withdrawalResponse, 0, len(withdrawals))
	for _, withdrawal := range withdrawals {
		response = append(response, withdrawalResponse{
			Order:       withdrawal.OrderNumber,
			Sum:         withdrawal.Sum,
			ProcessedAt: withdrawal.ProcessedAt,
		})
	}

	writeJSON(w, http.StatusOK, response)
}

// ExportStats обрабатывает POST /api/stats/export.
// Собирает статистику системы и записывает её в текстовый файл stats.txt
// в корне проекта. Возвращает 200 OK при успехе.
//
// Файл должен содержать:
//   - общее число зарегистрированных пользователей
//   - общее число заказов и их распределение по статусам
//   - суммарное количество начисленных баллов
//   - суммарное количество списанных баллов
//   - время генерации отчёта
//
// Для работы с файлами используйте пакет os (неделя 8).
func (h *Handler) ExportStats(w http.ResponseWriter, r *http.Request) {
	_, ok := UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Требуется авторизация", nil)
		return
	}

	users, err := h.svc.GetAllUsers()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
		return
	}

	orders, err := h.svc.GetAllOrders()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
		return
	}

	withdrawals, err := h.svc.GetAllWithdrawals()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера", err)
		return
	}

	newCount := 0
	processingCount := 0
	processedCount := 0
	invalidCount := 0
	totalAccrual := 0.0

	for _, order := range orders {
		switch order.Status {
		case domain.OrderStatusNew:
			newCount++
		case domain.OrderStatusProcessing:
			processingCount++
		case domain.OrderStatusProcessed:
			processedCount++
			totalAccrual += order.Accrual
		case domain.OrderStatusInvalid:
			invalidCount++
		}
	}

	totalWithdrawn := 0.0
	for _, withdrawal := range withdrawals {
		totalWithdrawn += withdrawal.Sum
	}

	report := strings.Join([]string{
		"users: " + strconv.Itoa(len(users)),
		"orders_total: " + strconv.Itoa(len(orders)),
		"orders_new: " + strconv.Itoa(newCount),
		"orders_processing: " + strconv.Itoa(processingCount),
		"orders_processed: " + strconv.Itoa(processedCount),
		"orders_invalid: " + strconv.Itoa(invalidCount),
		"total_accrual: " + strconv.FormatFloat(totalAccrual, 'f', -1, 64),
		"total_withdrawn: " + strconv.FormatFloat(totalWithdrawn, 'f', -1, 64),
		"report_generated_at: " + time.Now().Format(time.RFC3339),
	}, "\n")

	if err := os.WriteFile("stats.txt", []byte(report), 0644); err != nil {
		writeError(w, http.StatusInternalServerError, "EXPORT_FAILED", "Не удалось сохранить статистику", err)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// ---------------------------------------------------------------------------
// Вспомогательная функция для работы с контекстом - предоставлена
// ---------------------------------------------------------------------------

type contextKey string

const CtxKeyUserID contextKey = "userID"

// UserIDFromContext извлекает ID аутентифицированного пользователя из контекста.
// Возвращает 0, false если значение отсутствует.
func UserIDFromContext(ctx context.Context) (int64, bool) {
	// реализуйте самостоятельно
	userID, ok := ctx.Value(CtxKeyUserID).(int64)
	return userID, ok
}
