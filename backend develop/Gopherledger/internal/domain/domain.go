// Пакет domain содержит все бизнес-типы и сентинел-ошибки приложения.
// Этот пакет предоставлен и изменять его не нужно.
package domain

import (
	"errors"
	"time"
)

// ---------------------------------------------------------------------------
// Сентинел-ошибки
// ---------------------------------------------------------------------------

var (
	ErrUserExists        = errors.New("пользователь уже существует")
	ErrUserNotFound      = errors.New("пользователь не найден")
	ErrInvalidPassword   = errors.New("неверный пароль")
	ErrOrderExists       = errors.New("заказ уже загружен другим пользователем")
	ErrOrderOwnedByUser  = errors.New("заказ уже загружен этим пользователем")
	ErrInsufficientFunds = errors.New("недостаточно баллов")
	ErrInvalidOrder      = errors.New("неверный номер заказа")
)

// ---------------------------------------------------------------------------
// Модели
// ---------------------------------------------------------------------------

// User представляет зарегистрированного пользователя.
type User struct {
	ID           int64
	Login        string
	PasswordHash string
}

// Order представляет заказ, загруженный пользователем.
type Order struct {
	ID         int64
	UserID     int64
	Number     string
	Status     string
	Accrual    float64
	UploadedAt time.Time
}

// Balance представляет текущий баланс пользователя.
type Balance struct {
	Current   float64
	Withdrawn float64
}

// Withdrawal представляет операцию списания баллов.
type Withdrawal struct {
	ID          int64
	UserID      int64
	OrderNumber string
	Sum         float64
	ProcessedAt time.Time
}

// ---------------------------------------------------------------------------
// Константы статусов заказа
// ---------------------------------------------------------------------------

const (
	OrderStatusNew        = "NEW"
	OrderStatusProcessing = "PROCESSING"
	OrderStatusInvalid    = "INVALID"
	OrderStatusProcessed  = "PROCESSED"
)
