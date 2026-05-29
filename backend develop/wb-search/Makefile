APP=wb-search

.PHONY: run test bench docker-up docker-down

run:
	go run ./cmd/app

test:
	go test ./...

bench:
	go test -run '^$$' -bench . -benchmem ./internal/service

docker-up:
	docker compose up --build

docker-down:
	docker compose down -v
