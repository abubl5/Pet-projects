package model

import "time"

type SearchEvent struct {
	Query     string    `json:"query"`
	Timestamp time.Time `json:"timestamp"`
	UserID    string    `json:"user_id"`
	RequestID string    `json:"request_id"`
}
