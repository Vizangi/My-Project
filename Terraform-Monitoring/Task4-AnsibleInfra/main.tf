# Определение версии Terraform и требуемых провайдеров
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1" # Используем версию 3.x
    }
  }
  required_version = ">= 1.0"
}

# Инициализация провайдера Docker (в главном модуле)
provider "docker" {}

# Загружаем образ Debian (один раз в корневом модуле)
# Этот образ будет использоваться в модуле environment_servers
resource "docker_image" "debian" {
  name         = "debian:latest"
  keep_locally = false
}

# Вызываем модуль environment_servers для каждого контура, определенного в переменной environments
# for_each будет итерироваться по ключам (dev, staging, prod) переменной var.environments
module "environment_servers" {
  for_each = var.environments # Итерируемся по каждой паре ключ=значение в карте var.environments

  source   = "./modules/environment_servers" # Путь к нашему локальному модулю

  # Передаем входные переменные в модуль environment_servers
  # each.key - это текущий ключ итерации (например, "dev")
  # each.value - это текущий объект значения итерации ({ subnet_prefix="...", server_count=... })
  env_name      = each.key # Имя контура (dev, staging, prod)
  subnet_prefix = each.value.subnet_prefix # Префикс подсети для этого контура
  server_count  = each.value.server_count # Количество серверов для этого контура

  # Передаем учетные данные SSH из корневых переменных
  ssh_user      = var.ssh_user
  ssh_password  = var.ssh_password

}
