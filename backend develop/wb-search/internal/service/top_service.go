package service

import (
	"sort"
	"sync"
	"time"

	"wb-search/internal/model"
)

const (
	windowSizeSeconds = 300
	requestIDTTL      = 5 * time.Minute
	userQueryCooldown = 10 * time.Second
	maxFutureSkew     = 5 * time.Second
)

type TopItem struct {
	Query string `json:"query"`
	Count int    `json:"count"`
}

type bucket struct {
	second int64
	counts map[string]int
}

type TopService struct {
	mu           sync.RWMutex
	now          func() time.Time
	buckets      []bucket
	totalCounts  map[string]int
	seenRequests map[string]time.Time
	userCooldown map[string]time.Time
	stopWords    map[string]struct{}
}

func NewTopService() *TopService {
	buckets := make([]bucket, windowSizeSeconds)
	for i := range buckets {
		buckets[i] = bucket{
			counts: make(map[string]int),
		}
	}

	return &TopService{
		now:          time.Now,
		buckets:      buckets,
		totalCounts:  make(map[string]int),
		seenRequests: make(map[string]time.Time),
		userCooldown: make(map[string]time.Time),
		stopWords:    make(map[string]struct{}),
	}
}

func (s *TopService) Add(event model.SearchEvent) {
	query := model.NormalizeQuery(event.Query)
	if query == "" {
		return
	}

	now := s.now()
	if event.Timestamp.Before(now.Add(-5 * time.Minute)) {
		return
	}

	if event.Timestamp.After(now.Add(maxFutureSkew)) {
		return
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	s.cleanupBucketsLocked(now.Unix())
	s.cleanupMapsLocked(now)

	if !s.acceptRequestIDLocked(event.RequestID, now) {
		return
	}

	if !s.acceptUserQueryLocked(event.UserID, query, now) {
		return
	}

	second := event.Timestamp.Unix()
	index := int(second % int64(windowSizeSeconds))
	current := &s.buckets[index]

	if current.second != second {
		s.resetBucketLocked(index)
		current = &s.buckets[index]
		current.second = second
	}

	current.counts[query]++
	s.totalCounts[query]++
}

func (s *TopService) GetTop(limit int) []TopItem {
	if limit <= 0 {
		return []TopItem{}
	}

	now := s.now()

	s.mu.Lock()
	s.cleanupBucketsLocked(now.Unix())
	s.cleanupMapsLocked(now)

	items := make([]TopItem, 0, len(s.totalCounts))
	for query, count := range s.totalCounts {
		if _, blocked := s.stopWords[query]; blocked {
			continue
		}

		items = append(items, TopItem{
			Query: query,
			Count: count,
		})
	}
	s.mu.Unlock()

	sort.Slice(items, func(i, j int) bool {
		if items[i].Count == items[j].Count {
			return items[i].Query < items[j].Query
		}

		return items[i].Count > items[j].Count
	})

	if limit > len(items) {
		limit = len(items)
	}

	return items[:limit]
}

func (s *TopService) AddStopWord(word string) bool {
	word = model.NormalizeQuery(word)
	if word == "" {
		return false
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.stopWords[word]; exists {
		return false
	}

	s.stopWords[word] = struct{}{}
	return true
}

func (s *TopService) RemoveStopWord(word string) bool {
	word = model.NormalizeQuery(word)
	if word == "" {
		return false
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.stopWords[word]; !exists {
		return false
	}

	delete(s.stopWords, word)
	return true
}

func (s *TopService) ListStopWords() []string {
	s.mu.RLock()
	words := make([]string, 0, len(s.stopWords))
	for word := range s.stopWords {
		words = append(words, word)
	}
	s.mu.RUnlock()

	sort.Strings(words)
	return words
}

func (s *TopService) cleanupBucketsLocked(nowSecond int64) {
	minSecond := nowSecond - int64(windowSizeSeconds) + 1

	for i := range s.buckets {
		current := &s.buckets[i]
		if current.second == 0 {
			continue
		}

		if current.second < minSecond {
			s.resetBucketLocked(i)
		}
	}
}

func (s *TopService) resetBucketLocked(index int) {
	current := &s.buckets[index]

	for query, count := range current.counts {
		s.totalCounts[query] -= count
		if s.totalCounts[query] <= 0 {
			delete(s.totalCounts, query)
		}
	}

	clear(current.counts)
	current.second = 0
}

func (s *TopService) cleanupMapsLocked(now time.Time) {
	for requestID, expiresAt := range s.seenRequests {
		if !expiresAt.After(now) {
			delete(s.seenRequests, requestID)
		}
	}

	for key, expiresAt := range s.userCooldown {
		if !expiresAt.After(now) {
			delete(s.userCooldown, key)
		}
	}
}

func (s *TopService) acceptRequestIDLocked(requestID string, now time.Time) bool {
	if requestID == "" {
		return true
	}

	if expiresAt, exists := s.seenRequests[requestID]; exists && expiresAt.After(now) {
		return false
	}

	s.seenRequests[requestID] = now.Add(requestIDTTL)
	return true
}

func (s *TopService) acceptUserQueryLocked(userID, query string, now time.Time) bool {
	if userID == "" {
		return true
	}

	key := userID + "::" + query
	if expiresAt, exists := s.userCooldown[key]; exists && expiresAt.After(now) {
		return false
	}

	s.userCooldown[key] = now.Add(userQueryCooldown)
	return true
}
