// Пакет middleware содержит HTTP-middleware.
// Реализуйте Auth, Logging и Recover самостоятельно.
package middleware

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"gopherledger/internal/auth"
	"gopherledger/internal/handler"
)

var logLevel = "info"

type errorResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

// SetLogLevel задаёт уровень логирования middleware.
func SetLogLevel(level string) {
	if level == "" {
		logLevel = "info"
		return
	}
	logLevel = level
}

func writeJSONError(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(errorResponse{
		Code:    code,
		Message: message,
	}); err != nil {
		log.Printf("middleware writeJSONError: %v", err)
	}
}

// Auth проверяет токен из заголовка Authorization и помещает ID пользователя в контекст.
// Запросы без валидного токена получают ответ 401 Unauthorized.
//
// Что нужно сделать:
//   - прочитать токен из заголовка
//   - проверить токен через пакет auth
//   - поместить ID пользователя в контекст запроса
//   - передать управление следующему handler или вернуть 401
func Auth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("Authorization")
		if token == "" {
			writeJSONError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Требуется авторизация")
			return
		}

		userID, err := auth.ValidateToken(token)
		if err != nil {
			writeJSONError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Требуется авторизация")
			return
		}

		ctx := context.WithValue(r.Context(), handler.CtxKeyUserID, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// statusRecorder оборачивает http.ResponseWriter для перехвата статус-кода.
// Используйте эту структуру в Logging.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (sr *statusRecorder) WriteHeader(status int) {
	sr.status = status
	sr.ResponseWriter.WriteHeader(status)
}

func (sr *statusRecorder) Write(b []byte) (int, error) {
	if sr.status == 0 {
		sr.status = http.StatusOK
	}
	return sr.ResponseWriter.Write(b)
}

// Logging логирует метод, путь, статус ответа и время выполнения каждого запроса.
//
// Что нужно сделать:
//   - зафиксировать время начала запроса
//   - обернуть w в statusRecorder для перехвата статус-кода
//   - после выполнения handler записать лог
func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w}

		next.ServeHTTP(rec, r)

		if rec.status == 0 {
			rec.status = http.StatusOK
		}

		duration := time.Since(start)
		if logLevel == "debug" {
			log.Printf("method=%s path=%s status=%d duration=%s remote=%s user_agent=%q",
				r.Method, r.URL.Path, rec.status, duration, r.RemoteAddr, r.UserAgent())
			return
		}

		log.Printf("method=%s path=%s status=%d duration=%s",
			r.Method, r.URL.Path, rec.status, duration)
	})
}

// Recover перехватывает панику внутри handler, логирует её и возвращает
// клиенту ответ 500 Internal Server Error вместо того, чтобы уронить сервер.
//
// Что нужно сделать:
//   - добавить defer с вызовом recover()
//   - если паника произошла, залогировать её и отдать 500
func Recover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				log.Printf("panic: %v", rec)
				writeJSONError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Внутренняя ошибка сервера")
			}
		}()

		next.ServeHTTP(w, r)
	})
}
