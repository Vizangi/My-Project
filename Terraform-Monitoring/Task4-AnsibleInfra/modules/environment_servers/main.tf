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

  entrypoint = ["/usr/sbin/sshd"] # Запускаем SSHD

  command = [
    "/bin/bash",
    "-c",
    <<EOT
set -e # Прекратить выполнение скрипта при первой ошибке

echo "--- Running apt update ---"
apt update -y || { echo "apt update failed"; exit 1; } # Убедимся, что обновление прошло

echo "--- Installing MINIMAL essential packages for SSH and Ansible ---"
# Устанавливаем ТОЛЬКО openssh-server и python3, python3-apt, sudo
# Все остальные утилиты (ps, grep, find, ss и т.д.) УСТАНОВИМ ЧЕРЕЗ ANSIBLE
apt install -y openssh-server sudo python3 python3-apt || { echo "apt install minimal failed"; exit 1; }

echo "--- Creating SSHD runtime directory ---"
mkdir -p /run/sshd || { echo "mkdir /run/sshd failed"; exit 1; }

echo "--- Launching SSHD ---"
# Запускаем SSH демон в режиме "не-демона" (-D).
# Команда 'exec' заменяет текущий процесс оболочки на sshd.
exec /usr/sbin/sshd -D || { echo "sshd failed to start"; exit 1; }

echo "--- This line should not be reached ---"

EOT
  ]
  init = true
}
