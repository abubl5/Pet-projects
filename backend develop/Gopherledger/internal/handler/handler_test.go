package handler

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"gopherledger/internal/domain"
)

type fakeService struct {
	registerToken     string
	registerErr       error
	loginToken        string
	loginErr          error
	createOrderErr    error
	orders            []domain.Order
	ordersErr         error
	balance           domain.Balance
	balanceErr        error
	withdrawErr       error
	withdrawals       []domain.Withdrawal
	withdrawalsErr    error
	allUsers          []domain.User
	allUsersErr       error
	allOrders         []domain.Order
	allOrdersErr      error
	allWithdrawals    []domain.Withdrawal
	allWithdrawalsErr error
}

func (f *fakeService) RegisterUser(login, password string) (string, error) {
	return f.registerToken, f.registerErr
}

func (f *fakeService) LoginUser(login, password string) (string, error) {
	return f.loginToken, f.loginErr
}

func (f *fakeService) CreateOrder(userID int64, number string) (*domain.Order, error) {
	if f.createOrderErr != nil {
		return nil, f.createOrderErr
	}
	return &domain.Order{Number: number}, nil
}

func (f *fakeService) GetUserOrders(userID int64) ([]domain.Order, error) {
	return f.orders, f.ordersErr
}

func (f *fakeService) GetAllUsers() ([]domain.User, error) {
	return f.allUsers, f.allUsersErr
}

func (f *fakeService) GetAllOrders() ([]domain.Order, error) {
	return f.allOrders, f.allOrdersErr
}

func (f *fakeService) GetBalance(userID int64) (domain.Balance, error) {
	return f.balance, f.balanceErr
}

func (f *fakeService) Withdraw(userID int64, orderNumber string, sum float64) error {
	return f.withdrawErr
}

func (f *fakeService) GetWithdrawals(userID int64) ([]domain.Withdrawal, error) {
	return f.withdrawals, f.withdrawalsErr
}

func (f *fakeService) GetAllWithdrawals() ([]domain.Withdrawal, error) {
	return f.allWithdrawals, f.allWithdrawalsErr
}

func withUserID(req *http.Request, userID int64) *http.Request {
	ctx := context.WithValue(req.Context(), CtxKeyUserID, userID)
	return req.WithContext(ctx)
}

func TestRegister(t *testing.T) {
	tests := []struct {
		name       string
		body       string
		service    *fakeService
		wantStatus int
		wantAuth   bool
	}{
		{name: "success", body: `{"login":"alice","password":"secret"}`, service: &fakeService{registerToken: "token"}, wantStatus: http.StatusOK, wantAuth: true},
		{name: "duplicate", body: `{"login":"alice","password":"secret"}`, service: &fakeService{registerErr: domain.ErrUserExists}, wantStatus: http.StatusConflict},
		{name: "empty fields", body: `{"login":"","password":""}`, service: &fakeService{}, wantStatus: http.StatusUnauthorized},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h := New(tt.service)
			req := httptest.NewRequest(http.MethodPost, "/api/user/register", strings.NewReader(tt.body))
			rec := httptest.NewRecorder()

			h.Register(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("expected status %d, got %d", tt.wantStatus, rec.Code)
			}
			if tt.wantAuth && rec.Header().Get("Authorization") == "" {
				t.Fatal("expected Authorization header")
			}
		})
	}
}

func TestLogin(t *testing.T) {
	tests := []struct {
		name       string
		body       string
		service    *fakeService
		wantStatus int
	}{
		{name: "success", body: `{"login":"alice","password":"secret"}`, service: &fakeService{loginToken: "token"}, wantStatus: http.StatusOK},
		{name: "invalid credentials", body: `{"login":"alice","password":"bad"}`, service: &fakeService{loginErr: domain.ErrInvalidPassword}, wantStatus: http.StatusUnauthorized},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h := New(tt.service)
			req := httptest.NewRequest(http.MethodPost, "/api/user/login", strings.NewReader(tt.body))
			rec := httptest.NewRecorder()

			h.Login(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("expected status %d, got %d", tt.wantStatus, rec.Code)
			}
		})
	}
}

func TestCreateOrder(t *testing.T) {
	tests := []struct {
		name       string
		service    *fakeService
		wantStatus int
	}{
		{name: "success", service: &fakeService{}, wantStatus: http.StatusAccepted},
		{name: "invalid luhn", service: &fakeService{createOrderErr: domain.ErrInvalidOrder}, wantStatus: http.StatusUnprocessableEntity},
		{name: "same user duplicate", service: &fakeService{createOrderErr: domain.ErrOrderOwnedByUser}, wantStatus: http.StatusOK},
		{name: "other user duplicate", service: &fakeService{createOrderErr: domain.ErrOrderExists}, wantStatus: http.StatusConflict},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h := New(tt.service)
			req := httptest.NewRequest(http.MethodPost, "/api/user/orders", strings.NewReader("79927398713"))
			req = withUserID(req, 1)
			rec := httptest.NewRecorder()

			h.CreateOrder(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("expected status %d, got %d", tt.wantStatus, rec.Code)
			}
		})
	}
}

func TestGetOrders(t *testing.T) {
	haveAccrual := 100.5
	tests := []struct {
		name       string
		service    *fakeService
		wantStatus int
	}{
		{
			name: "with orders",
			service: &fakeService{orders: []domain.Order{
				{Number: "79927398713", Status: domain.OrderStatusProcessed, Accrual: haveAccrual, UploadedAt: time.Now()},
			}},
			wantStatus: http.StatusOK,
		},
		{name: "without orders", service: &fakeService{}, wantStatus: http.StatusNoContent},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h := New(tt.service)
			req := httptest.NewRequest(http.MethodGet, "/api/user/orders", nil)
			req = withUserID(req, 1)
			rec := httptest.NewRecorder()

			h.GetOrders(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("expected status %d, got %d", tt.wantStatus, rec.Code)
			}
			if tt.wantStatus == http.StatusOK && !strings.Contains(rec.Body.String(), `"number"`) {
				t.Fatalf("expected json body with snake_case fields, got %s", rec.Body.String())
			}
		})
	}
}

func TestGetBalance(t *testing.T) {
	h := New(&fakeService{balance: domain.Balance{Current: 300.5, Withdrawn: 100}})
	req := httptest.NewRequest(http.MethodGet, "/api/user/balance", nil)
	req = withUserID(req, 1)
	rec := httptest.NewRecorder()

	h.GetBalance(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), `"current"`) || !strings.Contains(rec.Body.String(), `"withdrawn"`) {
		t.Fatalf("expected snake_case balance fields, got %s", rec.Body.String())
	}
}

func TestWithdraw(t *testing.T) {
	tests := []struct {
		name       string
		service    *fakeService
		wantStatus int
	}{
		{name: "success", service: &fakeService{}, wantStatus: http.StatusOK},
		{name: "insufficient funds", service: &fakeService{withdrawErr: domain.ErrInsufficientFunds}, wantStatus: http.StatusPaymentRequired},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h := New(tt.service)
			req := httptest.NewRequest(http.MethodPost, "/api/user/balance/withdraw", bytes.NewBufferString(`{"order":"79927398713","sum":100}`))
			req = withUserID(req, 1)
			rec := httptest.NewRecorder()

			h.Withdraw(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("expected status %d, got %d", tt.wantStatus, rec.Code)
			}
		})
	}
}

func TestGetWithdrawals(t *testing.T) {
	tests := []struct {
		name       string
		service    *fakeService
		wantStatus int
	}{
		{
			name: "with records",
			service: &fakeService{withdrawals: []domain.Withdrawal{
				{OrderNumber: "79927398713", Sum: 100, ProcessedAt: time.Now()},
			}},
			wantStatus: http.StatusOK,
		},
		{name: "without records", service: &fakeService{}, wantStatus: http.StatusNoContent},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h := New(tt.service)
			req := httptest.NewRequest(http.MethodGet, "/api/user/withdrawals", nil)
			req = withUserID(req, 1)
			rec := httptest.NewRecorder()

			h.GetWithdrawals(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("expected status %d, got %d", tt.wantStatus, rec.Code)
			}
			if tt.wantStatus == http.StatusOK && !strings.Contains(rec.Body.String(), `"processed_at"`) {
				t.Fatalf("expected snake_case fields, got %s", rec.Body.String())
			}
		})
	}
}

func TestExportStats(t *testing.T) {
	service := &fakeService{
		allUsers: []domain.User{
			{ID: 1, Login: "alice"},
			{ID: 2, Login: "bob"},
		},
		allOrders: []domain.Order{
			{Number: "79927398713", Status: domain.OrderStatusProcessed, Accrual: 150},
			{Number: "1234567812345670", Status: domain.OrderStatusInvalid},
		},
		allWithdrawals: []domain.Withdrawal{
			{OrderNumber: "79927398713", Sum: 100},
		},
	}

	h := New(service)
	req := httptest.NewRequest(http.MethodPost, "/api/stats/export", nil)
	req = withUserID(req, 1)
	rec := httptest.NewRecorder()

	statsPath := "stats.txt"
	_ = os.Remove(statsPath)
	t.Cleanup(func() {
		_ = os.Remove(statsPath)
	})

	h.ExportStats(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}

	data, err := os.ReadFile(statsPath)
	if err != nil {
		t.Fatalf("expected stats file to be created: %v", err)
	}

	if !strings.Contains(string(data), "users: 2") {
		t.Fatalf("unexpected stats content: %s", string(data))
	}
}
