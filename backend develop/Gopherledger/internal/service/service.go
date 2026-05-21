// Пакет service содержит бизнес-логику приложения.
//
// Взаимодействие с хранилищем осуществляется через интерфейс.
// Определите этот интерфейс здесь, по месту использования.
package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"log"
	"math/rand"
	"sync"
	"time"

	"gopherledger/internal/auth"
	"gopherledger/internal/domain"
)

// Service реализует бизнес-логику приложения.
// Замените поле repo в структуре на свой интерфейс.
//
// processingOrders хранит номера заказов, которые сейчас обрабатываются воркером.
// Защитите конкурентный доступ к этому полю самостоятельно.
type Service struct {
	repo              Repository
	processingOrders  map[string]bool
	processingMu      sync.Mutex
	accrualInterval   time.Duration
	workerConcurrency int
}

type Repository interface {
	CreateUser(login, passwordHash string) (*domain.User, error)
	GetUserByLogin(login string) (*domain.User, error)
	CreateOrder(userID int64, number string) (*domain.Order, error)
	GetUserOrders(userID int64) ([]domain.Order, error)
	GetAllUsers() ([]domain.User, error)
	GetAllOrders() ([]domain.Order, error)
	GetOrdersForProcessing() ([]domain.Order, error)
	UpdateOrderStatus(number, status string, accrual float64) error
	GetBalance(userID int64) (domain.Balance, error)
	Withdraw(userID int64, orderNumber string, sum float64) error
	GetWithdrawals(userID int64) ([]domain.Withdrawal, error)
	GetAllWithdrawals() ([]domain.Withdrawal, error)
}

// New создаёт Service.
func New(repo Repository, accrualInterval time.Duration, workerConcurrency int) *Service {
	if accrualInterval <= 0 {
		accrualInterval = 3 * time.Second
	}
	if workerConcurrency <= 0 {
		workerConcurrency = 5
	}

	return &Service{
		repo:              repo,
		processingOrders:  make(map[string]bool),
		accrualInterval:   accrualInterval,
		workerConcurrency: workerConcurrency,
	}
}

// ---------------------------------------------------------------------------
// Методы бизнес-логики - реализуйте самостоятельно
// ---------------------------------------------------------------------------

// RegisterUser регистрирует нового пользователя и возвращает токен аутентификации.
// Хешируйте пароль перед сохранением с помощью crypto/sha256.
func (s *Service) RegisterUser(login, password string) (string, error) {
	hash := sha256.Sum256([]byte(password))
	passwordHash := hex.EncodeToString(hash[:])

	user, err := s.repo.CreateUser(login, passwordHash)
	if err != nil {
		return "", err
	}

	token, err := auth.GenerateToken(user.ID)
	if err != nil {
		return "", err
	}

	return token, nil
}

// LoginUser проверяет учётные данные и возвращает токен аутентификации.
func (s *Service) LoginUser(login, password string) (string, error) {
	user, err := s.repo.GetUserByLogin(login)
	if err != nil {
		return "", err
	}

	hash := sha256.Sum256([]byte(password))
	passwordHash := hex.EncodeToString(hash[:])

	if user.PasswordHash != passwordHash {
		return "", domain.ErrInvalidPassword
	}

	token, err := auth.GenerateToken(user.ID)
	if err != nil {
		return "", err
	}

	return token, nil
}

// CreateOrder проверяет номер заказа по алгоритму Луна и сохраняет заказ.
func (s *Service) CreateOrder(userID int64, number string) (*domain.Order, error) {
	if !validateLuhn(number) {
		return nil, domain.ErrInvalidOrder
	}

	return s.repo.CreateOrder(userID, number)
}

// GetUserOrders возвращает все заказы пользователя.
func (s *Service) GetUserOrders(userID int64) ([]domain.Order, error) {
	return s.repo.GetUserOrders(userID)
}

// GetBalance возвращает текущий баланс пользователя.
func (s *Service) GetBalance(userID int64) (domain.Balance, error) {
	return s.repo.GetBalance(userID)
}

// Withdraw проверяет номер заказа по алгоритму Луна и списывает сумму с баланса.
func (s *Service) Withdraw(userID int64, orderNumber string, sum float64) error {
	if !validateLuhn(orderNumber) {
		return domain.ErrInvalidOrder
	}

	return s.repo.Withdraw(userID, orderNumber, sum)
}

// GetWithdrawals возвращает историю списаний пользователя.
func (s *Service) GetWithdrawals(userID int64) ([]domain.Withdrawal, error) {
	return s.repo.GetWithdrawals(userID)
}

// GetAllUsers возвращает всех пользователей.
func (s *Service) GetAllUsers() ([]domain.User, error) {
	return s.repo.GetAllUsers()
}

// GetAllOrders возвращает все заказы.
func (s *Service) GetAllOrders() ([]domain.Order, error) {
	return s.repo.GetAllOrders()
}

// GetAllWithdrawals возвращает все списания.
func (s *Service) GetAllWithdrawals() ([]domain.Withdrawal, error) {
	return s.repo.GetAllWithdrawals()
}

// validateLuhn проверяет контрольную сумму номера заказа по алгоритму Луна.
// Вызывается при загрузке заказа и при списании баллов.
func validateLuhn(number string) bool {
	if number == "" {
		return false
	}

	sum := 0
	double := false

	for i := len(number) - 1; i >= 0; i-- {
		digit := int(number[i] - '0')

		if digit < 0 || digit > 9 {
			return false
		}

		if double {
			digit *= 2
			if digit > 9 {
				digit -= 9
			}
		}

		sum += digit
		double = !double
	}

	return sum%10 == 0
}

// ---------------------------------------------------------------------------
// Воркер начислений
//
// StartAccrualWorker предоставлен. Реализуйте processAllPendingOrders
// и processOrder самостоятельно.
//
// Это самая интересная часть проекта: конкурентная обработка заказов.
// Подумайте, как защитить доступ к processingOrders из нескольких горутин.
// ---------------------------------------------------------------------------

// StartAccrualWorker запускает фоновый цикл, который каждые 3 секунды
// передаёт необработанные заказы в processAllPendingOrders.
// Останавливается при отмене ctx.
func (s *Service) StartAccrualWorker(ctx context.Context) {
	ticker := time.NewTicker(s.accrualInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.processAllPendingOrders(ctx)
		}
	}
}

// processAllPendingOrders получает заказы для обработки и запускает горутины.
// Реализуйте самостоятельно.
func (s *Service) processAllPendingOrders(ctx context.Context) {
	orders, err := s.repo.GetOrdersForProcessing()
	if err != nil {
		log.Printf("воркер: ошибка получения заказов: %v", err)
		return
	}

	var wg sync.WaitGroup
	sem := make(chan struct{}, s.workerConcurrency)

	for _, order := range orders {
		s.processingMu.Lock()
		if s.processingOrders[order.Number] {
			s.processingMu.Unlock()
			continue
		}
		s.processingOrders[order.Number] = true
		s.processingMu.Unlock()

		wg.Add(1)
		sem <- struct{}{}

		number := order.Number

		go func() {
			defer wg.Done()
			defer func() { <-sem }()

			s.processOrder(ctx, number)
		}()
	}

	wg.Wait()
}

// processOrder обрабатывает один заказ. Реализуйте самостоятельно.
// Используйте вспомогательные функции ниже для генерации случайных значений.
func (s *Service) processOrder(ctx context.Context, number string) {
	defer func() {
		s.processingMu.Lock()
		delete(s.processingOrders, number)
		s.processingMu.Unlock()
	}()

	if err := s.repo.UpdateOrderStatus(number, domain.OrderStatusProcessing, 0); err != nil {
		log.Printf("воркер: ошибка установки PROCESSING для заказа %s: %v", number, err)
		return
	}

	select {
	case <-ctx.Done():
		return
	case <-time.After(randomDelay()):
	}

	if isInvalid() {
		if err := s.repo.UpdateOrderStatus(number, domain.OrderStatusInvalid, 0); err != nil {
			log.Printf("воркер: ошибка установки INVALID для заказа %s: %v", number, err)
		}
		return
	}

	accrual := randomAccrual()
	if err := s.repo.UpdateOrderStatus(number, domain.OrderStatusProcessed, accrual); err != nil {
		log.Printf("воркер: ошибка установки PROCESSED для заказа %s: %v", number, err)
	}
}

// ---------------------------------------------------------------------------
// Вспомогательные функции - предоставлены
// ---------------------------------------------------------------------------

// randomAccrual возвращает случайное начисление от 10 до 500 баллов.
func randomAccrual() float64 {
	return float64(rand.Intn(491) + 10)
}

// randomDelay возвращает случайную задержку от 2 до 6 секунд.
func randomDelay() time.Duration {
	return time.Duration(rand.Intn(5)+2) * time.Second
}

// isInvalid возвращает true примерно в 10% случаев.
func isInvalid() bool {
	return rand.Intn(10) == 0
}
