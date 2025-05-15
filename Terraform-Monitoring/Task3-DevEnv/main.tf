# Определение версии Terraform и требуемых провайдеров
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1" # Указываем версию провайдера Docker
    }
  }
  required_version = ">= 1.0" # Рекомендуется указывать минимальную версию Terraform CLI
}

# Инициализация провайдера Docker (в главном модуле он просто объявляется)
provider "docker" {}

# Загружаем образ Ubuntu (один раз в корневом модуле, т.к. он общий для всех)
resource "docker_image" "ubuntu" {
  name         = "ubuntu:latest"
  keep_locally = false
}

# Вызываем модуль environment для каждой среды, определенной в переменной environments
# for_each будет итерироваться по ключам (dev, staging, prod, test) переменной var.environments
module "environment" {
  for_each = var.environments # Итерируемся по каждой паре ключ=значение в карте var.environments

  source   = "./modules/environment" # Путь к нашему локальному модулю

  # Передаем входные переменные в модуль
  # each.key - это текущий ключ итерации (например, "dev")
  # each.value - это текущий объект значения итерации (например, { web_port = 8080, ... })
  env_name    = each.key                    # Имя среды (dev, staging, prod, test)
  web_port    = each.value.web_port         # Порт веб-сервера для этой среды
  db_user     = each.value.db_user          # Пользователь БД для этой среды
  db_password = each.value.db_password      # Пароль БД для этой среды
  db_name     = "${each.key}_db"            # Формируем имя базы данных (например, "dev_db")
  # Примечание: образ Ubuntu не передаем, так как он загружается в корневом модуле и доступен всем ресурсам
  # (хотя более правильно было бы передавать его ID или имя в модуль, если бы модуль был абсолютно независимым).
}
