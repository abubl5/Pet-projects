package store

import (
	"testing"

	"gopherledger/internal/domain"
)

func TestUserLifecycle(t *testing.T) {
	s := New()

	user, err := s.CreateUser("alice", "hash")
	if err != nil {
		t.Fatalf("CreateUser error: %v", err)
	}
	if user.Login != "alice" {
		t.Fatalf("unexpected user: %#v", user)
	}

	if _, err := s.CreateUser("alice", "hash"); err != domain.ErrUserExists {
		t.Fatalf("expected ErrUserExists, got %v", err)
	}

	got, err := s.GetUserByLogin("alice")
	if err != nil {
		t.Fatalf("GetUserByLogin error: %v", err)
	}
	if got.Login != "alice" {
		t.Fatalf("unexpected user: %#v", got)
	}

	if _, err := s.GetUserByLogin("bob"); err != domain.ErrUserNotFound {
		t.Fatalf("expected ErrUserNotFound, got %v", err)
	}
}

func TestOrderAndBalanceFlow(t *testing.T) {
	s := New()

	user1, _ := s.CreateUser("alice", "hash")
	user2, _ := s.CreateUser("bob", "hash")

	order, err := s.CreateOrder(user1.ID, "79927398713")
	if err != nil {
		t.Fatalf("CreateOrder error: %v", err)
	}
	if order.Status != domain.OrderStatusNew {
		t.Fatalf("expected NEW, got %s", order.Status)
	}

	if _, err := s.CreateOrder(user1.ID, "79927398713"); err != domain.ErrOrderOwnedByUser {
		t.Fatalf("expected ErrOrderOwnedByUser, got %v", err)
	}
	if _, err := s.CreateOrder(user2.ID, "79927398713"); err != domain.ErrOrderExists {
		t.Fatalf("expected ErrOrderExists, got %v", err)
	}

	orders, err := s.GetOrdersForProcessing()
	if err != nil || len(orders) != 1 {
		t.Fatalf("GetOrdersForProcessing got %d, err=%v", len(orders), err)
	}

	if err := s.UpdateOrderStatus("79927398713", domain.OrderStatusProcessed, 150); err != nil {
		t.Fatalf("UpdateOrderStatus error: %v", err)
	}

	balance, err := s.GetBalance(user1.ID)
	if err != nil {
		t.Fatalf("GetBalance error: %v", err)
	}
	if balance.Current != 150 {
		t.Fatalf("expected current 150, got %.2f", balance.Current)
	}

	if err := s.Withdraw(user1.ID, "1234567812345670", 50); err != nil {
		t.Fatalf("Withdraw error: %v", err)
	}

	balance, _ = s.GetBalance(user1.ID)
	if balance.Current != 100 || balance.Withdrawn != 50 {
		t.Fatalf("unexpected balance after withdraw: %#v", balance)
	}

	if err := s.Withdraw(user1.ID, "1234567812345670", 1000); err != domain.ErrInsufficientFunds {
		t.Fatalf("expected ErrInsufficientFunds, got %v", err)
	}

	withdrawals, err := s.GetWithdrawals(user1.ID)
	if err != nil || len(withdrawals) != 1 {
		t.Fatalf("GetWithdrawals got %d, err=%v", len(withdrawals), err)
	}

	userOrders, err := s.GetUserOrders(user1.ID)
	if err != nil || len(userOrders) != 1 {
		t.Fatalf("GetUserOrders got %d, err=%v", len(userOrders), err)
	}

	allUsers, _ := s.GetAllUsers()
	allOrders, _ := s.GetAllOrders()
	allWithdrawals, _ := s.GetAllWithdrawals()
	if len(allUsers) != 2 || len(allOrders) != 1 || len(allWithdrawals) != 1 {
		t.Fatalf("unexpected aggregate sizes users=%d orders=%d withdrawals=%d", len(allUsers), len(allOrders), len(allWithdrawals))
	}
}
