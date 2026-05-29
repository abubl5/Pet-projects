package service

import (
	"fmt"
	"testing"
	"time"

	"wb-search/internal/model"
)

func TestTopServiceAggregatesLastFiveMinutes(t *testing.T) {
	now := time.Date(2026, 5, 26, 15, 0, 0, 0, time.UTC)
	top := NewTopService()
	top.now = func() time.Time { return now }

	top.Add(model.SearchEvent{
		Query:     "Кроссовки, Nike!",
		Timestamp: now.Add(-2 * time.Minute),
		UserID:    "u1",
		RequestID: "r1",
	})
	top.Add(model.SearchEvent{
		Query:     "кроссовки nike",
		Timestamp: now.Add(-90 * time.Second),
		UserID:    "u2",
		RequestID: "r2",
	})
	top.Add(model.SearchEvent{
		Query:     "старый запрос",
		Timestamp: now.Add(-6 * time.Minute),
		UserID:    "u3",
		RequestID: "r3",
	})

	got := top.GetTop(10)
	if len(got) != 1 {
		t.Fatalf("expected 1 top item, got %d", len(got))
	}

	if got[0].Query != "кроссовки nike" || got[0].Count != 2 {
		t.Fatalf("unexpected top item: %+v", got[0])
	}
}

func TestTopServiceDeduplicatesRequestID(t *testing.T) {
	now := time.Date(2026, 5, 26, 15, 0, 0, 0, time.UTC)
	top := NewTopService()
	top.now = func() time.Time { return now }

	event := model.SearchEvent{
		Query:     "айфон 15",
		Timestamp: now.Add(-30 * time.Second),
		UserID:    "u1",
		RequestID: "same-request",
	}

	top.Add(event)
	top.Add(event)

	got := top.GetTop(10)
	if len(got) != 1 {
		t.Fatalf("expected 1 top item, got %d", len(got))
	}

	if got[0].Count != 1 {
		t.Fatalf("expected count 1 after duplicate request id, got %d", got[0].Count)
	}
}

func TestTopServiceUserCooldown(t *testing.T) {
	now := time.Date(2026, 5, 26, 15, 0, 0, 0, time.UTC)
	top := NewTopService()
	top.now = func() time.Time { return now }

	top.Add(model.SearchEvent{
		Query:     "lego",
		Timestamp: now.Add(-30 * time.Second),
		UserID:    "u1",
		RequestID: "r1",
	})
	top.Add(model.SearchEvent{
		Query:     "lego",
		Timestamp: now.Add(-29 * time.Second),
		UserID:    "u1",
		RequestID: "r2",
	})

	got := top.GetTop(10)
	if len(got) != 1 {
		t.Fatalf("expected 1 top item, got %d", len(got))
	}

	if got[0].Count != 1 {
		t.Fatalf("expected cooldown to keep count 1, got %d", got[0].Count)
	}
}

func TestTopServiceStopWords(t *testing.T) {
	now := time.Date(2026, 5, 26, 15, 0, 0, 0, time.UTC)
	top := NewTopService()
	top.now = func() time.Time { return now }

	top.Add(model.SearchEvent{
		Query:     "Айфон 15",
		Timestamp: now.Add(-30 * time.Second),
		UserID:    "u1",
		RequestID: "r1",
	})
	top.Add(model.SearchEvent{
		Query:     "кроссовки nike",
		Timestamp: now.Add(-20 * time.Second),
		UserID:    "u2",
		RequestID: "r2",
	})

	if !top.AddStopWord("айфон 15") {
		t.Fatal("expected stop word to be added")
	}

	got := top.GetTop(10)
	if len(got) != 1 {
		t.Fatalf("expected 1 visible item, got %d", len(got))
	}

	if got[0].Query != "кроссовки nike" {
		t.Fatalf("unexpected visible query: %+v", got[0])
	}
}

func TestTopServiceExpiresBucketsWhenTimeMoves(t *testing.T) {
	now := time.Date(2026, 5, 26, 15, 0, 0, 0, time.UTC)
	top := NewTopService()
	top.now = func() time.Time { return now }

	top.Add(model.SearchEvent{
		Query:     "платье",
		Timestamp: now.Add(-30 * time.Second),
		UserID:    "u1",
		RequestID: "r1",
	})

	now = now.Add(6 * time.Minute)

	got := top.GetTop(10)
	if len(got) != 0 {
		t.Fatalf("expected empty top after bucket expiration, got %+v", got)
	}
}

func BenchmarkTopServiceGetTop(b *testing.B) {
	now := time.Date(2026, 5, 26, 15, 0, 0, 0, time.UTC)
	top := NewTopService()
	top.now = func() time.Time { return now }

	for i := 0; i < 10000; i++ {
		top.Add(model.SearchEvent{
			Query:     fmt.Sprintf("query-%d", i%1000),
			Timestamp: now.Add(-time.Duration(i%240) * time.Second),
			UserID:    fmt.Sprintf("user-%d", i),
			RequestID: fmt.Sprintf("req-%d", i),
		})
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_ = top.GetTop(20)
	}
}
