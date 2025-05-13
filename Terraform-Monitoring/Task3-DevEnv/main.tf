# Определение версии Terraform и требуемых провайдеров
terraform {
  required_providers {
    docker = {                          # terraform подгружает из репозитория провайдер docker
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"              # Используем версию 3.x, которая ожидает environment как список строк
    }
  }
  required_version = ">= 1.0" # Рекомендуется указывать минимальную версию Terraform CLI
}

# Инициализация провайдера Docker
provider "docker" {}                    # terraform инициализирует провайдер docker

# Создаём Docker-сеть для изоляции контейнеров (как VPC в облаке)
resource "docker_network" "dev_network" {
  name = "dev-network"
}

# Загружаем образ Ubuntu для контейнеров
resource "docker_image" "ubuntu" {       # выбор ubuntu в качестве image
  name         = "ubuntu:latest"
  keep_locally = false # Можно установить true, если хотите оставить образ после destroy
}

# Создаём контейнер для веб-сервера (Nginx)
resource "docker_container" "dev_web" {
  name  = "dev-web"                      # Имя контейнера
  image = docker_image.ubuntu.name       # Используем образ Ubuntu (полное имя, включая тег)
  networks_advanced {
    name = docker_network.dev_network.name # Подключаем к сети dev-network по ее имени
  }
  ports {                               # Проброс портов из контейнера на хост
    internal = 80                       # Nginx внутри контейнера работает на порту 80
    external = var.web_port             # Внешний порт, задаётся в terraform.tfvars (и переменной web_port)
  }
  command = ["/bin/bash", "-c", "apt-get update -y && apt-get install -y nginx && nginx -g 'daemon off;'"]
  # Устанавливаем Nginx и запускаем его в режиме демона (не завершает работу сразу)
  # Добавлено -y для автоматического подтверждения установки apt
}

# Создаём контейнер для базы данных (PostgreSQL)
resource "docker_container" "dev_db" {
  name  = "dev-db"                       # Имя контейнера
  image = docker_image.ubuntu.name       # Используем образ Ubuntu (полное имя, включая тег)
  networks_advanced {
    name = docker_network.dev_network.name
  }
  env = [
    "POSTGRES_USER=${var.db_users[0].username}",     # Берем username ПЕРВОГО пользователя из списка (индекс 0)
    "POSTGRES_PASSWORD=${var.db_users[0].password}", # Берем password ПЕРВОГО пользователя из списка (индекс 0)
    "POSTGRES_DB=${var.db_name}"                    # Имя базы данных из переменной
  ]

  # Команда для выполнения внутри контейнера после его запуска
  command = [
    "/bin/bash",  # Указываем оболочку для выполнения команды
    "-c",         # Флаг -c bash'а, чтобы выполнить следующую строку как команду
    <<EOT
      # Установка PostgreSQL
      apt-get update -y && apt-get install -y postgresql -y && \ # Добавил -y для установки

      # Инициализация базы данных и запуск (выполняется от имени пользователя postgres)
      # initdb создает кластер БД. pg_ctl start запускает сервер.
      su - postgres -c 'initdb /var/lib/postgresql/data && pg_ctl -D /var/lib/postgresql/data -l /var/log/postgresql/startup.log start' && \

      # Подождать немного, пока база данных полностью стартует. 10 секунд обычно достаточно.
      sleep 10 && \

      # Создать основную базу данных, если она еще не создана.
      # Используем psql с параметрами подключения к локальному серверу от имени пользователя postgres.
      # -c выполняет команду SQL.
      su - postgres -c 'psql -c "CREATE DATABASE ${var.db_name}"' && \

      # Создать пользователей и выдать им права, используя цикл по переменной var.db_users
      # Этот цикл Terraform генерирует команды CREATE USER и GRANT для КАЖДОГО пользователя в списке var.db_users.
      %{ for user in var.db_users ~} # Начало цикла Terraform for
      su - postgres -c 'psql -c "CREATE USER ${user.username} WITH PASSWORD \\'${user.password}\\'"' && \ # Создание пользователя с экранированием одинарной кавычки \\'
      su - postgres -c 'psql -c "GRANT ALL PRIVILEGES ON DATABASE ${var.db_name} TO ${user.username}"' && \ # Выдача прав
      %{~ endfor ~} # Конец цикла Terraform for

      tail -f /dev/null
    EOT
  ]
}
