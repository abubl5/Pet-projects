package service

import (
	"errors"
	"testing"
	"time"

	"gopherledger/internal/domain"
)

type fakeStore struct {
	users            map[string]*domain.User
	orders           map[string]*domain.Order
	balances         map[int64]domain.Balance
	withdrawals      map[int64][]domain.Withdrawal
	nextUserID       int64
	nextOrderID      int64
	nextWithdrawalID int64
}

func newFakeStore() *fakeStore {
	return &fakeStore{
		users:            make(map[string]*domain.User),
		orders:           make(map[string]*domain.Order),
		balances:         make(map[int64]domain.Balance),
		withdrawals:      make(map[int64][]domain.Withdrawal),
		nextUserID:       1,
		nextOrderID:      1,
		nextWithdrawalID: 1,
	}
}

func (f *fakeStore) CreateUser(login, passwordHash string) (*domain.User, error) {
	if _, exists := f.users[login]; exists {
		return nil, domain.ErrUserExists
	}
	user := &domain.User{
		ID:           f.nextUserID,
		Login:        login,
		PasswordHash: passwordHash,
	}
	f.nextUserID++
	f.users[login] = user
	f.balances[user.ID] = domain.Balance{}
	userCopy := *user
	return &userCopy, nil
}

func (f *fakeStore) GetUserByLogin(login string) (*domain.User, error) {
	user, exists := f.users[login]
	if !exists {
		return nil, domain.ErrUserNotFound
	}
	userCopy := *user
	return &userCopy, nil
}

func (f *fakeStore) CreateOrder(userID int64, number string) (*domain.Order, error) {
	if existing, exists := f.orders[number]; exists {
		if existing.UserID == userID {
			return nil, domain.ErrOrderOwnedByUser
		}
		return nil, domain.ErrOrderExists
	}
	order := &domain.Order{
		ID:         f.nextOrderID,
		UserID:     userID,
		Number:     number,
		Status:     domain.OrderStatusNew,
		UploadedAt: time.Now(),
	}
	f.nextOrderID++
	f.orders[number] = order
	orderCopy := *order
	return &orderCopy, nil
}

func (f *fakeStore) GetUserOrders(userID int64) ([]domain.Order, error) {
	var orders []domain.Order
	for _, order := range f.orders {
		if order.UserID == userID {
			orders = append(orders, *order)
		}
	}
	return orders, nil
}

func (f *fakeStore) GetAllUsers() ([]domain.User, error) {
	var users []domain.User
	for _, user := range f.users {
		users = append(users, *user)
	}
	return users, nil
}

func (f *fakeStore) GetAllOrders() ([]domain.Order, error) {
	var orders []domain.Order
	for _, order := range f.orders {
		orders = append(orders, *order)
	}
	return orders, nil
}

func (f *fakeStore) GetOrdersForProcessing() ([]domain.Order, error) {
	return nil, nil
}

func (f *fakeStore) UpdateOrderStatus(number, status string, accrual float64) error {
	order, exists := f.orders[number]
	if !exists {
		return domain.ErrInvalidOrder
	}
	order.Status = status
	order.Accrual = accrual
	return nil
}

func (f *fakeStore) GetBalance(userID int64) (domain.Balance, error) {
	return f.balances[userID], nil
}

func (f *fakeStore) Withdraw(userID int64, orderNumber string, sum float64) error {
	balance := f.balances[userID]
	if balance.Current < sum {
		return domain.ErrInsufficientFunds
	}
	balance.Current -= sum
	balance.Withdrawn += sum
	f.balances[userID] = balance
	f.withdrawals[userID] = append(f.withdrawals[userID], domain.Withdrawal{
		ID:          f.nextWithdrawalID,
		UserID:      userID,
		OrderNumber: orderNumber,
		Sum:         sum,
		ProcessedAt: time.Now(),
	})
	f.nextWithdrawalID++
	return nil
}

func (f *fakeStore) GetWithdrawals(userID int64) ([]domain.Withdrawal, error) {
	return append([]domain.Withdrawal(nil), f.withdrawals[userID]...), nil
}

func (f *fakeStore) GetAllWithdrawals() ([]domain.Withdrawal, error) {
	var withdrawals []domain.Withdrawal
	for _, userWithdrawals := range f.withdrawals {
		withdrawals = append(withdrawals, userWithdrawals...)
	}
	return withdrawals, nil
}

func TestRegisterUser(t *testing.T) {
	store := newFakeStore()
	svc := New(store, time.Second, 1)

	tests := []struct {
		name    string
		login   string
		wantErr error
	}{
		{name: "success", login: "alice"},
		{name: "duplicate", login: "alice", wantErr: domain.ErrUserExists},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			token, err := svc.RegisterUser(tt.login, "secret")
			if !errors.Is(err, tt.wantErr) {
				t.Fatalf("expected error %v, got %v", tt.wantErr, err)
			}
			if tt.wantErr == nil && token == "" {
				t.Fatal("expected non-empty token")
			}
		})
	}
}

func TestLoginUser(t *testing.T) {
	store := newFakeStore()
	svc := New(store, time.Second, 1)

	if _, err := svc.RegisterUser("alice", "secret"); err != nil {
		t.Fatalf("setup register failed: %v", err)
	}

	tests := []struct {
		name     string
		login    string
		password string
		wantErr  error
	}{
		{name: "success", login: "alice", password: "secret"},
		{name: "wrong password", login: "alice", password: "wrong", wantErr: domain.ErrInvalidPassword},
		{name: "user not found", login: "bob", password: "secret", wantErr: domain.ErrUserNotFound},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			token, err := svc.LoginUser(tt.login, tt.password)
			if !errors.Is(err, tt.wantErr) {
				t.Fatalf("expected error %v, got %v", tt.wantErr, err)
			}
			if tt.wantErr == nil && token == "" {
				t.Fatal("expected non-empty token")
			}
		})
	}
}

func TestCreateOrder(t *testing.T) {
	store := newFakeStore()
	svc := New(store, time.Second, 1)

	tests := []struct {
		name    string
		userID  int64
		number  string
		wantErr error
	}{
		{name: "success", userID: 1, number: "79927398713"},
		{name: "invalid luhn", userID: 1, number: "1234567890", wantErr: domain.ErrInvalidOrder},
		{name: "same user duplicate", userID: 1, number: "79927398713", wantErr: domain.ErrOrderOwnedByUser},
		{name: "other user duplicate", userID: 2, number: "79927398713", wantErr: domain.ErrOrderExists},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			order, err := svc.CreateOrder(tt.userID, tt.number)
			if !errors.Is(err, tt.wantErr) {
				t.Fatalf("expected error %v, got %v", tt.wantErr, err)
			}
			if tt.wantErr == nil && order == nil {
				t.Fatal("expected order")
			}
		})
	}
}

func TestWithdraw(t *testing.T) {
	store := newFakeStore()
	store.balances[1] = domain.Balance{Current: 100}
	svc := New(store, time.Second, 1)

	tests := []struct {
		name        string
		userID      int64
		order       string
		sum         float64
		wantErr     error
		wantCurrent float64
	}{
		{name: "success", userID: 1, order: "79927398713", sum: 40, wantCurrent: 60},
		{name: "insufficient funds", userID: 1, order: "79927398713", sum: 1000, wantErr: domain.ErrInsufficientFunds, wantCurrent: 60},
		{name: "invalid luhn", userID: 1, order: "1234567890", sum: 10, wantErr: domain.ErrInvalidOrder, wantCurrent: 60},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := svc.Withdraw(tt.userID, tt.order, tt.sum)
			if !errors.Is(err, tt.wantErr) {
				t.Fatalf("expected error %v, got %v", tt.wantErr, err)
			}
			balance, _ := store.GetBalance(tt.userID)
			if balance.Current != tt.wantCurrent {
				t.Fatalf("expected current %.2f, got %.2f", tt.wantCurrent, balance.Current)
			}
		})
	}
}
