# Coder Sample: Full Stack Dev Environment

Шаблон рабочей среды Coder для полного стека разработки.

## Стек

| Сервис | Описание | Порт |
|--------|----------|------|
| Node.js | Бэкенд API (workspace) | 3000 |
| React | Фронтенд (Vite) | 5173 |
| PostgreSQL | База данных | 5432 |
| RabbitMQ | Брокер сообщений | 5672 (AMQP), 15672 (Management UI) |
| Airflow | Оркестрация задач | 8080 |

## Вариант 1: Coder Template (main.tf)

Используется с платформой Coder для создания cloud workspace:

```bash
# Инициализировать шаблон
coder templates init

# Создать workspace
coder create my-workspace
```

Все сервисы запускаются как Docker-контейнеры внутри workspace через `docker compose up -d`.

## Вариант 2: Docker Compose (docker-compose.yml)

Для локального тестирования без Coder:

```bash
# Запустить все сервисы
docker compose up -d

# Остановить
docker compose down
```

## Вариант 3: Dev Container (devcontainer.json)

Для VS Code / Cursor / Windsurf с поддержкой devcontainer:

Откройте папку в VS Code → "Reopen in Container"

## Структура проекта

```
.
├── main.tf              # Terraform конфигурация для Coder
├── docker-compose.yml   # Docker Compose для всех сервисов
├── Dockerfile           # Образ для workspace контейнера
├── devcontainer.json    # Конфигурация devcontainer
├── airflow/
│   └── dags/            # Airflow DAG-и
└── workspace/
    ├── backend/         # Node.js API
    └── frontend/        # React приложение
```

## Переменные окружения

| Переменная | Значение | Описание |
|------------|----------|----------|
| DATABASE_URL | postgresql://dev:***@postgres:5432/app | Подключение к PostgreSQL |
| RABBITMQ_URL | amqp://dev:***@rabbitmq:5672 | Подключение к RabbitMQ |
| AIRFLOW_URL | http://airflow:8080 | URL Airflow |
| NODE_ENV | development | Режим Node.js |

## Автор

[alsovdev](https://github.com/alsovdev)
