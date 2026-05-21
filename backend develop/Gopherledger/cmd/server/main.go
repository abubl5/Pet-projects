// Точка входа сервера. Реализуйте самостоятельно.
//
// Порядок инициализации:
//  1. Загрузить конфигурацию (пакет config)
//  2. Создать хранилище (пакет store)
//  3. Создать сервис (пакет service)
//  4. Запустить воркер начислений в горутине (svc.StartAccrualWorker)
//  5. Создать обработчик и роутер (пакеты handler, router)
//  6. Запустить HTTP-сервер
//  7. Реализовать graceful shutdown по сигналам SIGINT и SIGTERM
package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gopherledger/internal/config"
	"gopherledger/internal/handler"
	"gopherledger/internal/middleware"
	"gopherledger/internal/router"
	"gopherledger/internal/service"
	"gopherledger/internal/store"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	st := store.New()
	svc := service.New(
		st,
		time.Duration(cfg.AccrualIntervalSeconds)*time.Second,
		cfg.WorkerConcurrency,
	)

	middleware.SetLogLevel(cfg.LogLevel)

	h := handler.New(svc)
	r := router.New(h)

	server := &http.Server{
		Addr:    fmt.Sprintf("%s:%d", cfg.ServerHost, cfg.ServerPort),
		Handler: r,
	}

	workerCtx, workerCancel := context.WithCancel(context.Background())
	defer workerCancel()

	go svc.StartAccrualWorker(workerCtx)

	go func() {
		log.Printf("server started on %s", server.Addr)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	<-sigCh

	workerCancel()

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Printf("shutdown error: %v", err)
	}
}
