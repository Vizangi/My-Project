terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

# Ресурсы для ОДНОГО контура (сети и серверов)

# Создаем Docker-сеть для этого контура.
resource "docker_network" "network" {     # Логическое имя ресурса внутри модуля
  name = "${var.env_name}-network"        # Имя сети в Docker
  ipam_config {                           # Определяем конфигурацию IPAM для сети
    subnet = "${var.subnet_prefix}.0/24"  # Задаем подсеть
    # gateway = "${var.subnet_prefix}.1   # можно задать Gateway, но обычно Docker назначает .1 по умолчанию
  }
}

# Создаем несколько контейнеров-серверов для этого контура

resource "docker_container" "server" {
  count = var.server_count
  name = "${var.env_name}-server-${count.index}"
  image = "debian:latest"

  networks_advanced {
    name = docker_network.network.name   # Подключаем к сети, созданной ВНУТРИ ЭТОГО ЖЕ вызова модуля
    ipv4_address = "${var.subnet_prefix}.${10 + count.index}"
  }

  command = [
    "/bin/bash",
    "-c",
    <<EOT
      apt update -y
      apt install -y openssh-server systemd sudo # Устанавливаем пакеты, включая sudo

      # Создаем пользователя для SSH (Ansible user)
      useradd -m -s /bin/bash ${var.ssh_user}
      echo "${var.ssh_user}:${var.ssh_password}" | chpasswd # Устанавливаем пароль пользователю

      # Настраиваем SSHD: разрешаем аутентификацию по паролю
      # Это нужно для Ansible, который может использовать пароли. В реальной жизни - SSH ключи!
      sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config # Опционально, если нужен root login (не рекомендуется)
      sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config # Разрешаем парольную аутентификацию

      # Добавляем пользователя в sudoers (для выполнения команд от root через Ansible)
      # NOPASSWD:ALL означает, что sudo не будет запрашивать пароль для этого пользователя
      echo "${var.ssh_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-ansible-user
      chmod 0440 /etc/sudoers.d/99-ansible-user

      # Запускаем SSH демон в режиме "не-демона" (-D) чтобы он оставался основным процессом контейнера
      /usr/sbin/sshd -D
    EOT
  ]
  # Опционально: добавьте restart policy
  # restart = "on-failure"
}
