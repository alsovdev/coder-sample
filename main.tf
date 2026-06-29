terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  username = data.coder_workspace_owner.me.name
}

variable "docker_socket" {
  default     = ""
  description = "(Optional) Docker socket URI"
  type        = string
}

provider "docker" {
  host = var.docker_socket != "" ? var.docker_socket : null
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  startup_script = <<-EOT
    set -e
    cd /home/coder/project
    docker compose up -d

    echo "✅ Все сервисы запущены:"
    echo "  - Node.js API:    http://localhost:3000"
    echo "  - React Frontend: http://localhost:5173"
    echo "  - PostgreSQL:     localhost:5432"
    echo "  - RabbitMQ:       localhost:5672 (mgmt: 15672)"
    echo "  - Airflow:        http://localhost:8080"
  EOT

  env = {
    GIT_AUTHOR_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL = "${data.coder_workspace_owner.me.email}"
  }
}

# PostgreSQL
resource "docker_container" "postgres" {
  name  = "coder-${local.username}-postgres"
  image = "postgres:16-alpine"

  env = [
    "POSTGRES_USER=dev",
    "POSTGRES_PASSWORD=dev",
    "POSTGRES_DB=app"
  ]

  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = "coder-pgdata-${local.username}"
  }

  ports {
    internal = 5432
    external = 5432
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U dev"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# RabbitMQ
resource "docker_container" "rabbitmq" {
  name  = "coder-${local.username}-rabbitmq"
  image = "rabbitmq:3.13-management-alpine"

  env = [
    "RABBITMQ_DEFAULT_USER=dev",
    "RABBITMQ_DEFAULT_PASS=dev"
  ]

  ports {
    internal = 5672
    external = 5672
  }
  ports {
    internal = 15672
    external = 15672
  }

  healthcheck {
    test     = ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# Airflow
resource "docker_container" "airflow" {
  name  = "coder-${local.username}-airflow"
  image = "apache/airflow:2.9.3-python3.11"

  env = [
    "AIRFLOW__CORE__EXECUTOR=LocalExecutor",
    "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://dev:dev@postgres:5432/app",
    "AIRFLOW__CORE__LOAD_EXAMPLES=false",
    "AIRFLOW__WEBSERVER__SECRET_KEY=secret"
  ]

  volumes {
    host_path      = "/home/coder/project/airflow/dags"
    container_path = "/opt/airflow/dags"
  }

  ports {
    internal = 8080
    external = 8080
  }

  depends_on = [docker_container.postgres, docker_container.rabbitmq]

  healthcheck {
    test     = ["CMD", "curl", "--fail", "http://localhost:8080/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 5
  }
}

# Node.js workspace (основная рабочая среда)
resource "docker_container" "workspace" {
  name  = "coder-${local.username}-workspace"
  image = "mcr.microsoft.com/devcontainers/javascript-node:20-bookworm"

  command = ["sleep", "infinity"]

  env = [
    "DATABASE_URL=postgresql://dev:dev@postgres:5432/app",
    "RABBITMQ_URL=amqp://dev:dev@rabbitmq:5672",
    "AIRFLOW_URL=http://airflow:8080",
    "NODE_ENV=development"
  ]

  volumes {
    host_path      = "/home/coder/project/workspace"
    container_path = "/home/coder/project"
  }

  ports {
    internal = 3000
    external = 3000
  }
  ports {
    internal = 5173
    external = 5173
  }

  depends_on = [docker_container.postgres, docker_container.rabbitmq, docker_container.airflow]
}
