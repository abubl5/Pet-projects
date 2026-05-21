// Пакет auth отвечает за генерацию и проверку токенов аутентификации.
// Токен - это случайная уникальная строка (например, UUID или hex-строка),
// которая однозначно связана с конкретным пользователем.
//
// Внутри пакета нужно хранить соответствие токен -> userID.
// Используйте для этого map с защитой от конкурентного доступа.
// Реализуйте этот пакет самостоятельно.
package auth

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"sync"
)

// ErrInvalidToken возвращается, если токен не найден или недействителен.
var ErrInvalidToken = errors.New("недействительный токен")

var (
	tokens = make(map[string]int64)
	mu     sync.RWMutex
)

// GenerateToken создаёт новый токен для пользователя с указанным ID
// и сохраняет связь токен -> userID внутри пакета.
func GenerateToken(userID int64) (string, error) {
	b := make([]byte, 16)

	if _, err := rand.Read(b); err != nil {
		return "", err
	}

	token := hex.EncodeToString(b)

	mu.Lock()
	tokens[token] = userID
	mu.Unlock()

	return token, nil
}

// ValidateToken проверяет токен и возвращает ID пользователя.
// Возвращает ErrInvalidToken если токен не найден.
func ValidateToken(token string) (int64, error) {
	mu.RLock()
	userID, exists := tokens[token]
	mu.RUnlock()

	if !exists {
		return 0, ErrInvalidToken
	}

	return userID, nil
}
