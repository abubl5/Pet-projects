# wb-search

Сервис считает топ поисковых запросов за последние 5 минут на основе событий из Kafka и отдает результат по HTTP API.

Что делает сервис:
- читает события поиска из Kafka;
- агрегирует запросы в скользящем окне 5 минут;
- отдает `топ` запросов по API;
- поддерживает динамический stop-list без перезапуска;
- отсекает простые дубли;
- также учтена логика против простой накрутки

Что из ТЗ реализовано:

| Пункт | Статус | Комментарий |
|---|---|---|
| Брокер сообщений | `Да` | Чтение событий из Kafka через `segmentio/kafka-go` |
| Метод получения топ-запросов за 5 минут | `Да` | `GET /top?n=...` |
| Динамический stop-list | `Да` | Добавление/удаление через HTTP API |
| Unit-тесты ключевой логики | `Да` | Покрыт `TopService` |
| Нагрузочное тестирование / benchmark | `Частично` | Есть Go benchmark для сценария чтения топа |
| удобный и быстрый локальный запуск | `Да` | `docker compose up --build` |
| Мониторинг | `Нет` | Не реализован |

## Stack

- Go 1.24
- `net/http`
- Kafka
- `github.com/segmentio/kafka-go`
- Docker / Docker Compose

Внешние хранилища вроде PostgreSQL или Redis в проекте не используются.  
Все данные для активного окна хранятся в памяти процесса.

## Run locally - минимальная проверка работоспособности

```bash
git clone <repo-url>
cd wb-search
docker compose up --build

открыть второй терминал

docker exec -i wb-kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic search-events

вставить тестовые данные во второй терминал предварительно указав в timestamp каждого поискового запроса время не раньше чем текущее -300 секунд: вот пример

{"query":"Кроссовки, Nike!","timestamp":"2026-05-26T18:26:10Z","user_id":"user-1","request_id":"req-101"}
{"query":"кроссовки nike","timestamp":"2026-05-26T18:26:15Z","user_id":"user-2","request_id":"req-102"}
{"query":"Кроссовки Nike","timestamp":"2026-05-26T18:26:20Z","user_id":"user-3","request_id":"req-103"}
{"query":"Айфон 15","timestamp":"2026-05-26T18:26:25Z","user_id":"user-4","request_id":"req-104"}
{"query":"айфон 15","timestamp":"2026-05-26T18:26:30Z","user_id":"user-5","request_id":"req-105"}
{"query":"айфон 15","timestamp":"2026-05-26T18:26:35Z","user_id":"user-6","request_id":"req-106"}
{"query":"Платье летнее","timestamp":"2026-05-26T18:26:40Z","user_id":"user-7","request_id":"req-107"}
{"query":"платье летнее","timestamp":"2026-05-26T18:26:45Z","user_id":"user-8","request_id":"req-108"}
{"query":"Платье, летнее!","timestamp":"2026-05-26T18:26:50Z","user_id":"user-9","request_id":"req-109"}
{"query":"Lego technic","timestamp":"2026-05-26T18:26:55Z","user_id":"user-10","request_id":"req-110"}
{"query":"lego technic","timestamp":"2026-05-26T18:27:00Z","user_id":"user-11","request_id":"req-111"}
{"query":"Наушники bluetooth","timestamp":"2026-05-26T18:27:05Z","user_id":"user-12","request_id":"req-112"}
{"query":"наушники bluetooth","timestamp":"2026-05-26T18:27:10Z","user_id":"user-13","request_id":"req-113"}
{"query":"Наушники, bluetooth","timestamp":"2026-05-26T18:27:15Z","user_id":"user-14","request_id":"req-114"}
{"query":"Самокат детский","timestamp":"2026-05-26T18:27:20Z","user_id":"user-15","request_id":"req-115"}
{"query":"самокат детский","timestamp":"2026-05-26T18:27:25Z","user_id":"user-16","request_id":"req-116"}
{"query":"Футболка oversize","timestamp":"2026-05-26T18:27:30Z","user_id":"user-17","request_id":"req-117"}
{"query":"футболка oversize","timestamp":"2026-05-26T18:27:35Z","user_id":"user-18","request_id":"req-118"}
{"query":"Чехол iphone 15","timestamp":"2026-05-26T18:27:40Z","user_id":"user-19","request_id":"req-119"}
{"query":"чехол iphone 15","timestamp":"2026-05-26T18:27:45Z","user_id":"user-20","request_id":"req-120"}

открыть результат

control + c - прервать сеанс в терминале

curl "http://localhost:8080/top?n=2" где ?n = сколько хотите увидеть в топе 
```

После запуска:
- HTTP API доступен на `http://localhost:8080`
- Kafka доступна на `localhost:29092` с хоста и на `kafka:9092` внутри `docker compose`

Проверка health:

```bash
curl "http://localhost:8080/health"
```

Ответ:

```json
{"status":"ok"}
```

### Env-переменные

| Переменная | По умолчанию |
|---|---|
| `HTTP_PORT` | `8080` |
| `KAFKA_BROKERS` | `localhost:29092` |
| `KAFKA_TOPIC` | `search-events` |
| `KAFKA_GROUP_ID` | `wb-search-top` |
| `KAFKA_START_OFFSET` | `-1` |

## API

### `GET /health`

Проверка, что HTTP-сервис запущен.

```bash
curl "http://localhost:8080/health"
```

Ответ:

```json
{"status":"ok"}
```

### `GET /top`

Возвращает топ запросов за последние 5 минут.

Параметры:

| Query param | Обязательный | Описание |
|---|---|---|
| `n` | нет | сколько элементов вернуть, по умолчанию `10` |

Пример:

```bash
curl "http://localhost:8080/top?n=5"
```

Ответ:

```json
{
  "top": [
    {
      "query": "кроссовки nike",
      "count": 2
    },
    {
      "query": "айфон 15",
      "count": 1
    }
  ]
}
```

Ошибка при невалидном `n`:

```json
{"message":"query parameter n must be a positive integer"}
```

### `GET /stop-words`

Возвращает текущий stop-list.

```bash
curl "http://localhost:8080/stop-words"
```

Ответ:

```json
{"words":["айфон 15"]}
```

### `POST /stop-words`

Добавляет stop-word.

```bash
curl -X POST "http://localhost:8080/stop-words" \
  -H "Content-Type: application/json" \
  -d '{"word":"айфон 15"}'
```

Ответ:

```json
{"message":"stop word added"}
```

### `DELETE /stop-words/{word}`

Удаляет stop-word.

```bash
curl -X DELETE "http://localhost:8080/stop-words/%D0%B0%D0%B9%D1%84%D0%BE%D0%BD%2015"
```
здесь в curl закодированное слово 

Ответ:

```json
{"message":"stop word removed"}
```

## Контракт данных

Формат события:

```json
{
  "query": "Кроссовки, Nike!",
  "timestamp": "2026-05-26T14:26:30Z",
  "user_id": "user-1",
  "request_id": "req-11"
}
```

Поля:

| Поле | Зачем нужно |
|---|---|
| `query` | текст поискового запроса |
| `timestamp` | попадание события в окно последних 5 минут |
| `user_id` | простая защита от накрутки |
| `request_id` | дедупликация повторно доставленных событий |

Почему нужны именно эти поля:

- `query` нужен для самого подсчета популярности;
- `timestamp` нужен, потому что сервис считает только последние 5 минут;
- `user_id` нужен для простой защиты от слишком частых повторов;
- `request_id` нужен для дедупликации повторно доставленного события.

## Project Structure

```text
cmd/app/                 точка входа
internal/broker/         Kafka consumer
internal/config/         чтение конфигурации
internal/httpapi/        HTTP handlers
internal/model/          входные модели и нормализация запроса
internal/service/        бизнес-логика агрегации топа
outputs/                 benchmark output
docker-compose.yml       локальный запуск Kafka + app
Dockerfile               сборка приложения в контейнер
Makefile                 короткие команды для запуска, тестов и benchmark
```

## Обоснование архитектуры

Поток данных:

```text
Kafka -> Consumer -> TopService -> HTTP API
```

`TopService` хранит окно в памяти через кольцевой массив из `300` бакетов:
- `300` бакетов = `300` секунд = `5` минут;
- каждый бакет хранит агрегаты запросов для одной секунды;
- поверх бакетов есть `totalCounts`, из которого быстро собирается ответ для `/top`.

Основная нагрузка по ТЗ — частые чтения, а не записи, поэтому важно было сделать дешевой именно выдачу топа.

Что выбрано для хранения топа:
- секундные бакеты для ограничения окна;
- общий `map[string]int` по активному окну;
- in-memory хранение без БД.

Почему выбраны именно такие структуры данных:
- старые данные удаляются без полного пересчета;
- память ограничена размером окна;
- чтение топа не требует обхода всех сырых событий.

Stop-list не выбрасывает данные из внутренней статистики, а скрывает их только в ответе API.

Плюсы такого решения:
- можно менять stop-list тут же;
- не нужен пересчет окна;
- если слово удалили из stop-list, оно снова начнет показываться, пока еще живет в 5-минутном окне.

Для stop-list выбрана `map[string]struct{}`:
- проверка наличия слова быстрая;
- структура простая;
- дополнительных зависимостей не нужно.

## Trade-offs и бизнес-логика

Компромиссы ради производительности:

- данные хранятся только в памяти, поэтому после рестарта окно теряется;
- отдельная БД не используется, чтобы не добавлять лишнюю задержку на горячем пути;
- окно считается по секундам, а не по миллисекундам;
- stop-list тоже хранится в памяти.

Бизнес-логика:

- запрос нормализуется перед подсчетом;
- одинаковый `request_id` повторно не учитывается;
- один и тот же пользователь не может слишком часто поднимать один и тот же запрос;
- старые события и события слишком далеко из будущего игнорируются;
- запросы из stop-list скрываются из выдачи.

Проблемы в постановке задачи и как они решены:

1. Не был задан формат payload в брокере.  
   Решение: введен контракт с полями `query`, `timestamp`, `user_id`, `request_id`.

2. Не было сказано, как именно очищать старые данные.  
   Решение: кольцевой буфер из 300 секундных бакетов.

3. Не было четкого определения накрутки.  
   Решение: дедупликация по `request_id` и cooldown по `user_id + query`.

4. Не было определено, что считать одинаковыми запросами.  
   Решение: нормализация строки перед подсчетом.

5. Не было определено, что делать с некорректным временем события.  
   Решение: старые и слишком будущие события игнорируются.

## Как запускать тесты

Все тесты:
```bash
Тестами покрыта ключевая бизнес логика, а именно:
  подсчет топа в окне 5 минут;
  игнорирование старых событий;
  дедупликация по request_id;
  cooldown по user_id + query;
  stop-list;
  очистка данных при движении времени.
```


```bash
go test ./...
```

Benchmark:

```bash
go test -run '^$' -bench . -benchmem ./internal/service
```

Последний замер из проекта:

```text
BenchmarkTopServiceGetTop-10    	    4022	    292339 ns/op	   24672 B/op	       4 allocs/op
```

Также можно использовать `Makefile`:

```bash
make test
make bench
make docker-up
make docker-down
```
