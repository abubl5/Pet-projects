package broker

import (
	"context"
	"encoding/json"
	"errors"
	"log"

	"github.com/segmentio/kafka-go"

	"wb-search/internal/config"
	"wb-search/internal/model"
	"wb-search/internal/service"
)

type Consumer struct {
	reader *kafka.Reader
	top    *service.TopService
}

func NewConsumer(cfg config.Config, top *service.TopService) *Consumer {
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:     cfg.KafkaBrokers,
		Topic:       cfg.KafkaTopic,
		GroupID:     cfg.KafkaGroupID,
		StartOffset: cfg.KafkaStartOffset,
		MinBytes:    1,
		MaxBytes:    10e6,
	})

	return &Consumer{
		reader: reader,
		top:    top,
	}
}

func (c *Consumer) Run(ctx context.Context) error {
	defer c.reader.Close()

	for {
		msg, err := c.reader.ReadMessage(ctx)
		if err != nil {
			if errors.Is(err, context.Canceled) {
				return nil
			}

			return err
		}

		var event model.SearchEvent
		if err := json.Unmarshal(msg.Value, &event); err != nil {
			log.Printf("skip bad kafka message: %v", err)
			continue
		}

		c.top.Add(event)
	}
}
