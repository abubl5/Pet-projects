package httpapi

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"wb-search/internal/service"
)

type Handler struct {
	top *service.TopService
}

type stopWordRequest struct {
	Word string `json:"word"`
}

type topResponse struct {
	Top []service.TopItem `json:"top"`
}

type stopWordsResponse struct {
	Words []string `json:"words"`
}

type messageResponse struct {
	Message string `json:"message"`
}

type healthResponse struct {
	Status string `json:"status"`
}

func NewHandler(top *service.TopService) *Handler {
	return &Handler{top: top}
}

func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.handleHealth)
	mux.HandleFunc("GET /top", h.handleGetTop)
	mux.HandleFunc("GET /stop-words", h.handleListStopWords)
	mux.HandleFunc("POST /stop-words", h.handleAddStopWord)
	mux.HandleFunc("DELETE /stop-words/{word}", h.handleDeleteStopWord)
}

func (h *Handler) handleHealth(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, healthResponse{Status: "ok"})
}

func (h *Handler) handleGetTop(w http.ResponseWriter, r *http.Request) {
	limit := 10

	if rawLimit := r.URL.Query().Get("n"); rawLimit != "" {
		parsedLimit, err := strconv.Atoi(rawLimit)
		if err != nil || parsedLimit <= 0 {
			writeJSON(w, http.StatusBadRequest, messageResponse{
				Message: "query parameter n must be a positive integer",
			})
			return
		}

		limit = parsedLimit
	}

	writeJSON(w, http.StatusOK, topResponse{
		Top: h.top.GetTop(limit),
	})
}

func (h *Handler) handleListStopWords(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, stopWordsResponse{
		Words: h.top.ListStopWords(),
	})
}

func (h *Handler) handleAddStopWord(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var req stopWordRequest
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()

	if err := decoder.Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, messageResponse{
			Message: "invalid json body",
		})
		return
	}

	if !h.top.AddStopWord(req.Word) {
		writeJSON(w, http.StatusBadRequest, messageResponse{
			Message: "word is empty or already exists",
		})
		return
	}

	writeJSON(w, http.StatusCreated, messageResponse{
		Message: "stop word added",
	})
}

func (h *Handler) handleDeleteStopWord(w http.ResponseWriter, r *http.Request) {
	word := strings.TrimSpace(r.PathValue("word"))
	if word == "" {
		writeJSON(w, http.StatusBadRequest, messageResponse{
			Message: "word is required",
		})
		return
	}

	if !h.top.RemoveStopWord(word) {
		writeJSON(w, http.StatusNotFound, messageResponse{
			Message: "stop word not found",
		})
		return
	}

	writeJSON(w, http.StatusOK, messageResponse{
		Message: "stop word removed",
	})
}

func writeJSON(w http.ResponseWriter, statusCode int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(data)
}
