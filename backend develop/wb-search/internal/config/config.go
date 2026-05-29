package config

import (
	"errors"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	HTTPPort        string
	KafkaBrokers    []string
	KafkaTopic      string
	KafkaGroupID    string
	KafkaStartOffset int64
}

func Load() (Config, error) {
	cfg := Config{
		HTTPPort:         getEnv("HTTP_PORT", "8080"),
		KafkaBrokers:     splitCSV(getEnv("KAFKA_BROKERS", "localhost:29092")),
		KafkaTopic:       getEnv("KAFKA_TOPIC", "search-events"),
		KafkaGroupID:     getEnv("KAFKA_GROUP_ID", "wb-search-top"),
		KafkaStartOffset: getEnvInt64("KAFKA_START_OFFSET", -1),
	}

	if cfg.HTTPPort == "" {
		return Config{}, errors.New("HTTP_PORT is empty")
	}

	if len(cfg.KafkaBrokers) == 0 {
		return Config{}, errors.New("KAFKA_BROKERS is empty")
	}

	if cfg.KafkaTopic == "" {
		return Config{}, errors.New("KAFKA_TOPIC is empty")
	}

	if cfg.KafkaGroupID == "" {
		return Config{}, errors.New("KAFKA_GROUP_ID is empty")
	}

	if cfg.KafkaStartOffset != -1 && cfg.KafkaStartOffset != -2 {
		return Config{}, errors.New("KAFKA_START_OFFSET must be -1 or -2")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}

	return value
}

func getEnvInt64(key string, fallback int64) int64 {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}

	parsed, err := strconv.ParseInt(value, 10, 64)
	if err != nil {
		return fallback
	}

	return parsed
}

func splitCSV(value string) []string {
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))

	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}

		result = append(result, part)
	}

	return result
}
