# Ресурсы, которые описывают одну среду (Environment)
# Эти ресурсы будут созданы МНОГОКРАТНО (по одному разу для каждой среды),
# благодаря вызову модуля с for_each в корневом main.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

# Создаём сеть для этой среды
resource "docker_network" "network" { # Comment
  name = "${var.env_name}-network" # Имя сети в Docker формируется из входной переменной модуля
}

# Создаём контейнер для веб-сервера в этой среде
resource "docker_container" "web" {
  name  = "${var.env_name}-web" # Имя контейнера в Docker формируется из входной переменной модуля
  image = "ubuntu:latest" # Используем образ Ubuntu, который должен быть доступен (например, скачан в корневом модуле)
  networks_advanced {
    name = docker_network.network.name # Подключаем к сети, созданной ВНУТРИ ЭТОГО ЖЕ вызова модуля
  }
  ports {
    internal = 80
    external = var.web_port # Внешний порт берется из входной переменной модуля
  }
  command = ["/bin/bash", "-c", "apt-get update -y && apt-get install -y nginx -y && nginx -g 'daemon off;'"] # Команда установки/запуска
}

# Создаём контейнер для базы данных в этой среде
resource "docker_container" "db" { 
  name  = "${var.env_name}-db" # Имя контейнера в Docker формируется из входной переменной модуля
  image = "ubuntu:latest" # Используем образ Ubuntu
  networks_advanced {
    name = docker_network.network.name # Подключаем к сети, созданной ВНУТРИ ЭТОГО ЖЕ вызова модуля
  }
  # Переменные окружения для начальной настройки PostgreSQL (используем 'env')
  # Важно: для провайдера Docker версии 3.x это ДОЛЖЕН быть СПИСОК СТРОК "КЛЮЧ=ЗНАЧЕНИЕ"
  env = [ # <--- Используем 'env' вместо 'environment'
    "POSTGRES_USER=${var.db_user}",     # Пользователь берется из входной переменной модуля
    "POSTGRES_PASSWORD=${var.db_password}", # Пароль берется из входной переменной модуля
    "POSTGRES_DB=${var.db_name}"        # Имя базы данных берется из входной переменной модуля
  ]
  # Команда установки и запуска PostgreSQL
command = [
  "/bin/bash",
  "-c",
  <<EOT
    # Установка PostgreSQL
    apt-get update -y && apt-get install -y postgresql -y && \

    # Инициализация базы данных
    su - postgres -c 'initdb /var/lib/postgresql/data' && \

    # Запуск сервера БД
    su - postgres -c 'pg_ctl -D /var/lib/postgresql/data -l /var/log/postgresql/startup.log start' && \

    # Подождать, пока база полностью стартует
    sleep 15 && \ # Увеличил ожидание

    # Создать базу данных (выполняется от имени пользователя postgres)
    su - postgres -c 'psql -c "CREATE DATABASE ${var.db_name}"' && \

    # Держать контейнер запущенным
    tail -f /dev/null
  EOT
]
}
