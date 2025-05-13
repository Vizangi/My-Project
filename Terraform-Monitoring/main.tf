# Конфигурация провайдера Docker
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1" # Убедитесь, что эта версия или совместимая установлена
    }
  }
}

provider "docker" {}

# Определение образа Debian
resource "docker_image" "debian_image" {
  name         = "debian:latest"
  keep_locally = false # Можно установить true, если хотите оставить образ после destroy
}

# Определение образа CentOS
resource "docker_image" "centos_image" {
  name         = "centos:centos7"
  keep_locally = false # Можно установить true, если хотите оставить образ после destroy
}

# Создание 10 пустых контейнеров Debian
resource "docker_container" "empty_debian_container" {
  count = 10 # Создаем 10 экземпляров этого ресурса

  # Используем ID образа Debian, определенного выше
  image = docker_image.debian_image.image_id

  # Динамическое имя для каждого контейнера с использованием его индекса (0 до 9)
  name  = "debian-container-${count.index}"

  # Команда, которая будет выполняться при запуске контейнера,
  # чтобы он оставался в фоне (аналог демонизации)
  command = ["tail", "-f", "/dev/null"]

  # Можно добавить другие настройки при необходимости, но для "пустых" контейнеров этого достаточно
  # ports { ... } # Порты в этой задаче не нужны
}

# Создание 10 пустых контейнеров CentOS
resource "docker_container" "empty_centos_container" {
  count = 10 # Создаем 10 экземпляров этого ресурса

  # Используем ID образа CentOS, определенного выше
  image = docker_image.centos_image.image_id

  # Динамическое имя для каждого контейнера с использованием его индекса (0 до 9)
  name  = "centos-container-${count.index}"

  # Команда для поддержания работы контейнера в фоне
  command = ["tail", "-f", "/dev/null"]

  # Другие настройки по умолчанию
}
