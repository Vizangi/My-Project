# Объявление провайдеров, необходимых ДЛЯ ЭТОГО МОДУЛЯ
# Это блок должен быть в самом начале файла модуля
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1" # Версия должна быть совместима с версией в корневом модуле
    }
  }
  required_version = ">= 1.0" # Рекомендуется указывать минимальную версию Terraform CLI
}

# Ресурсы для ОДНОГО контура (сети и серверов)

# Создаём Docker-сеть для этого контура.
resource "docker_network" "network" {     # Логическое имя ресурса внутри модуля
  name = "${var.env_name}-network"        # Имя сети в Docker
  ipam_config {                           # Определяем конфигурацию IPAM для сети
    subnet = "${var.subnet_prefix}.0/24"  # Задаем подсеть, например "172.20.0.0/24"
    # gateway = "${var.subnet_prefix}.1"   # можно задать Gateway, но обычно Docker назначает .1 по умолчанию
  }
}

# Создаём несколько контейнеров-серверов для этого контура
# count создаст var.server_count (например, 8) экземпляров этого ресурса
resource "docker_container" "server" {
  count = var.server_count # Количество экземпляров = var.server_count

  name = "${var.env_name}-server-${count.index}" # Имя контейнера в Docker: dev-server-0, ..., prod-server-7
  image = "debian:latest" # Используем образ Debian

  networks_advanced {
    name = docker_network.network.name   # Подключаем к сети, созданной ВНУТРИ ЭТОГО ЖЕ вызова модуля
    # Присваиваем уникальный статический IP в подсети
    # Начинаем, например, с .10, чтобы избежать конфликта с возможным .1 (gateway)
    ipv4_address = "${var.subnet_prefix}.${10 + count.index}"
  }

  # entrypoint = ["/usr/sbin/sshd"] # <--- Убедитесь, что эта строка ЗАКОММЕНТИРОВАНА или УДАЛЕНА!

  command = [
    "/bin/bash",  # Указываем оболочку для выполнения команды
    "-c",         # Флаг -c bash'а, чтобы выполнить следующую строку как команду
    <<-EOT_SCRIPT
      # Теперь содержимое скрипта МОЖЕТ иметь отступ, выравнивая его
      # с остальным кодом HCL для читаемости.
      set -e # Остановить скрипт при первой ошибке

      echo "--- Running apt update ---"
      apt update -y || { echo "apt update failed"; exit 1; } # Убедимся, что обновление прошло

      echo "--- Installing MINIMAL essential packages for SSH and Ansible ---"
      # Устанавливаем ТОЛЬКО openssh-server и python3, python3-apt, sudo
      # Все остальные утилиты (ps, grep, find, ss и т.д.) УСТАНОВИМ ЧЕРЕЗ ANSIBLE
      apt install -y openssh-server sudo python3 python3-apt || { echo "apt install minimal failed"; exit 1; }

      echo "--- Creating SSHD runtime directory ---"
      # sshd нуждается в этой директории для своего PID файла и других нужд
      mkdir -p /run/sshd || { echo "mkdir /run/sshd failed"; exit 1; }

      echo "--- Creating user ${var.ssh_user} ---"
      # Проверяем, существует ли пользователь, прежде чем создавать
      if ! id "${var.ssh_user}" &>/dev/null; then
          useradd -m -s /bin/bash ${var.ssh_user} || { echo "useradd failed"; exit 1; }
          echo "User ${var.ssh_user} created."
      else
          echo "User ${var.ssh_user} already exists."
      fi

      echo "--- Setting password for user ${var.ssh_user} ---"
      # Устанавливаем пароль пользователю.
      # Используем функцию replace для корректного экранирования $ внутри строки для chpasswd.
      echo "${var.ssh_user}:${replace(var.ssh_password, "$", "\\$")}" | chpasswd || { echo "chpasswd failed"; exit 1; }
      echo "Password set."

      echo "--- Configuring SSHD ---"
      # Перезаписываем строки, чтобы явно установить PasswordAuthentication и PermitRootLogin.
      # Это надежнее, чем sed с заменой, который может не сработать, если строки уже есть или их нет.
      sed -i '/^PasswordAuthentication/ d' /etc/ssh/sshd_config
      echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config || { echo "echo PasswordAuthentication failed"; exit 1; }
      sed -i '/^PermitRootLogin/ d' /etc/ssh/sshd_config
      echo "PermitRootLogin no" >> /etc/ssh/sshd_config || { echo "echo PermitRootLogin failed"; exit 1; }
      # Если нужно разрешить RootLogin, используйте 'echo "PermitRootLogin yes" >> ...' вместо 'no'

      echo "--- Adding user ${var.ssh_user} to sudoers with NOPASSWD ---"
      echo "${var.ssh_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-ansible-user || { echo "echo sudoers failed"; exit 1; }
      chmod 0440 /etc/sudoers.d/99-ansible-user || { echo "chmod sudoers failed"; exit 1; }
      echo "Sudoers file created and permissions set."

      echo "--- Launching SSHD ---"
      # Запускаем SSH демон в режиме "не-демона" (-D).
      # Команда 'exec' заменяет текущий процесс оболочки (/bin/bash) на sshd.
      # sshd -D остается PID 1 и держит контейнер живым.
      exec /usr/sbin/sshd -D || { echo "FATAL: sshd failed to start, container will exit."; exit 1; }

      echo "--- This line should ideally not be reached ---"

    EOT_SCRIPT
      ]
      init = true # Рекомендуется для контейнеров, запускающих сервисы (лучше обрабатывает сигналы)
      # Опционально: добавьте restart policy
      # restart = "on-failure"
    }
