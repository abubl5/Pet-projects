FROM golang:1.24 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/wb-search ./cmd/app

FROM debian:stable-slim

WORKDIR /app

COPY --from=builder /out/wb-search /app/wb-search

EXPOSE 8080

CMD ["/app/wb-search"]
