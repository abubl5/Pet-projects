// Пакет store реализует хранилище данных в памяти.
// Используйте отдельные мьютексы для независимых групп данных.
// Реализуйте этот пакет самостоятельно.
package store

import (
	"gopherledger/internal/domain"
	"sort"
	"sync"
	"time"
)

// Store хранит все данные приложения в памяти.
// Добавьте средства защиты конкурентного доступа самостоятельно.
type Store struct {
	// users хранит пользователей по их ID
	users map[int64]*domain.User

	// usersByLogin хранит пользователей по логину - для быстрого поиска при авторизации
	usersByLogin map[string]*domain.User

	// orders хранит заказы по номеру заказа
	orders map[string]*domain.Order

	// balances хранит текущий баланс каждого пользователя по его ID
	balances map[int64]*domain.Balance

	// withdrawals хранит историю списаний для каждого пользователя по его ID
	withdrawals map[int64][]*domain.Withdrawal

	// nextID используется для генерации уникальных числовых ID
	nextID int64

	usersMu       sync.RWMutex
	ordersMu      sync.RWMutex
	balancesMu    sync.RWMutex
	withdrawalsMu sync.RWMutex
	idMu          sync.Mutex
}

// New создаёт и возвращает новое пустое хранилище.
func New() *Store {
	return &Store{
		users:        make(map[int64]*domain.User),
		usersByLogin: make(map[string]*domain.User),
		orders:       make(map[string]*domain.Order),
		balances:     make(map[int64]*domain.Balance),
		withdrawals:  make(map[int64][]*domain.Withdrawal),
		nextID:       1,
	}
}

// CreateUser добавляет нового пользователя.
// Возвращает domain.ErrUserExists если логин уже занят.
func (s *Store) CreateUser(login, passwordHash string) (*domain.User, error) {
	s.usersMu.Lock()

	defer s.usersMu.Unlock()

	if _, exist := s.usersByLogin[login]; exist {
		return nil, domain.ErrUserExists
	}

	s.idMu.Lock()
	userID := s.nextID
	s.nextID++
	s.idMu.Unlock()

	user := &domain.User{
		ID:           userID,
		Login:        login,
		PasswordHash: passwordHash,
	}

	s.users[userID] = user
	s.usersByLogin[login] = user

	s.balancesMu.Lock()
	s.balances[userID] = &domain.Balance{}
	s.balancesMu.Unlock()

	userCopy := *user
	return &userCopy, nil
}

// GetUserByLogin возвращает пользователя по логину.
// Возвращает domain.ErrUserNotFound если пользователь не найден.
func (s *Store) GetUserByLogin(login string) (*domain.User, error) {
	s.usersMu.RLock()

	defer s.usersMu.RUnlock()

	user, exist := s.usersByLogin[login]
	if !exist {
		return nil, domain.ErrUserNotFound
	}

	userCopy := *user
	return &userCopy, nil
}

// CreateOrder добавляет новый заказ для пользователя.
// Возвращает domain.ErrOrderOwnedByUser если этот пользователь уже загружал этот номер.
// Возвращает domain.ErrOrderExists если номер принадлежит другому пользователю.
func (s *Store) CreateOrder(userID int64, number string) (*domain.Order, error) {
	s.ordersMu.Lock()
	defer s.ordersMu.Unlock()

	if existingOrder, exists := s.orders[number]; exists {
		if existingOrder.UserID == userID {
			return nil, domain.ErrOrderOwnedByUser
		}
		return nil, domain.ErrOrderExists
	}

	s.idMu.Lock()
	orderID := s.nextID
	s.nextID++
	s.idMu.Unlock()

	order := &domain.Order{
		ID:         orderID,
		UserID:     userID,
		Number:     number,
		Status:     domain.OrderStatusNew,
		UploadedAt: time.Now(),
	}
	s.orders[number] = order

	orderCopy := *order
	return &orderCopy, nil
}

// GetUserOrders возвращает все заказы пользователя, сначала новые.
func (s *Store) GetUserOrders(userID int64) ([]domain.Order, error) {
	s.ordersMu.RLock()
	defer s.ordersMu.RUnlock()

	var orders []domain.Order
	for _, order := range s.orders {
		if order.UserID == userID {
			orders = append(orders, *order)
		}
	}

	sort.Slice(orders, func(i, j int) bool {
		return orders[i].UploadedAt.After(orders[j].UploadedAt)
	})

	return orders, nil
}

// GetOrdersForProcessing возвращает все заказы в статусе NEW или PROCESSING.
func (s *Store) GetOrdersForProcessing() ([]domain.Order, error) {
	s.ordersMu.RLock()
	defer s.ordersMu.RUnlock()

	var orders []domain.Order
	for _, order := range s.orders {
		if order.Status == domain.OrderStatusProcessing || order.Status == domain.OrderStatusNew {
			orders = append(orders, *order)
		}
	}

	return orders, nil
}

// UpdateOrderStatus обновляет статус и начисление заказа.
// Если статус PROCESSED и accrual > 0, баланс пользователя пополняется.
func (s *Store) UpdateOrderStatus(number, status string, accrual float64) error {
	s.ordersMu.Lock()
	order, exist := s.orders[number]
	if !exist {
		s.ordersMu.Unlock()
		return domain.ErrInvalidOrder
	}

	order.Status = status
	order.Accrual = accrual
	userID := order.UserID
	s.ordersMu.Unlock()

	if status == domain.OrderStatusProcessed && accrual > 0 {
		s.balancesMu.Lock()
		balance, exist := s.balances[userID]
		if !exist {
			balance = &domain.Balance{}
			s.balances[userID] = balance
		}
		balance.Current += accrual
		s.balancesMu.Unlock()
	}

	return nil
}

// GetBalance возвращает баланс пользователя.
func (s *Store) GetBalance(userID int64) (domain.Balance, error) {
	s.balancesMu.RLock()
	defer s.balancesMu.RUnlock()

	balance, exist := s.balances[userID]
	if !exist {
		return domain.Balance{}, nil
	}
	return *balance, nil
}

// Withdraw списывает сумму с баланса и записывает операцию.
// Возвращает domain.ErrInsufficientFunds если баланса не хватает.
// Обе операции должны быть атомарны: либо обе успешны, либо ни одна.
func (s *Store) Withdraw(userID int64, orderNumber string, sum float64) error {
	s.balancesMu.Lock()
	defer s.balancesMu.Unlock()

	balance, exist := s.balances[userID]

	if !exist {
		balance = &domain.Balance{}
		s.balances[userID] = balance
	}

	if balance.Current < sum {
		return domain.ErrInsufficientFunds
	}

	s.withdrawalsMu.Lock()
	defer s.withdrawalsMu.Unlock()

	s.idMu.Lock()
	withdrawalID := s.nextID
	s.nextID++
	s.idMu.Unlock()

	balance.Current -= sum
	balance.Withdrawn += sum

	withdrawal := &domain.Withdrawal{
		ID:          withdrawalID,
		UserID:      userID,
		OrderNumber: orderNumber,
		Sum:         sum,
		ProcessedAt: time.Now(),
	}

	s.withdrawals[userID] = append(s.withdrawals[userID], withdrawal)

	return nil
}

// GetWithdrawals возвращает историю списаний пользователя, сначала новые.
func (s *Store) GetWithdrawals(userID int64) ([]domain.Withdrawal, error) {
	s.withdrawalsMu.RLock()
	defer s.withdrawalsMu.RUnlock()

	var withdrawals []domain.Withdrawal
	for _, withdrawal := range s.withdrawals[userID] {
		withdrawals = append(withdrawals, *withdrawal)
	}

	sort.Slice(withdrawals, func(i, j int) bool {
		return withdrawals[i].ProcessedAt.After(withdrawals[j].ProcessedAt)
	})

	return withdrawals, nil
}

// GetAllUsers возвращает всех пользователей.
func (s *Store) GetAllUsers() ([]domain.User, error) {
	s.usersMu.RLock()
	defer s.usersMu.RUnlock()

	users := make([]domain.User, 0, len(s.users))
	for _, user := range s.users {
		users = append(users, *user)
	}

	return users, nil
}

// GetAllOrders возвращает все заказы.
func (s *Store) GetAllOrders() ([]domain.Order, error) {
	s.ordersMu.RLock()
	defer s.ordersMu.RUnlock()

	orders := make([]domain.Order, 0, len(s.orders))
	for _, order := range s.orders {
		orders = append(orders, *order)
	}

	return orders, nil
}

// GetAllWithdrawals возвращает все списания всех пользователей.
func (s *Store) GetAllWithdrawals() ([]domain.Withdrawal, error) {
	s.withdrawalsMu.RLock()
	defer s.withdrawalsMu.RUnlock()

	var withdrawals []domain.Withdrawal
	for _, userWithdrawals := range s.withdrawals {
		for _, withdrawal := range userWithdrawals {
			withdrawals = append(withdrawals, *withdrawal)
		}
	}

	sort.Slice(withdrawals, func(i, j int) bool {
		return withdrawals[i].ProcessedAt.After(withdrawals[j].ProcessedAt)
	})

	return withdrawals, nil
}
