# outputs.tf

# Выходная переменная, которая собирает IP-адреса всех созданных серверов со ВСЕХ контуров
# Используем функцию flatten для "сплющивания" списка списков в один плоский список.
# Внутри flatten, используем for-выражение для итерации по карте вызовов модуля
# и сбора списка IP-адресов из выходной переменной 'container_ips' КАЖДОГО модуля.
output "server_ips" {
  description = "List of IP addresses of all created server containers"
  # [ for key, value in collection : result ] - стандартный синтаксис for
  value = flatten([ # Используем функцию flatten
    for env_name, module_output in module.environment_servers : # Итерация по карте модулей. Результат цикла - список.
    module_output.container_ips # Для каждого модуля возвращаем список IP из его output 'container_ips'. Цикл собирает их в список списков.
  ])
  # flatten([ [ip1, ip2], [ip3, ip4] ]) -> [ip1, ip2, ip3, ip4]
}

/* # <--- Начало многострочного комментария
# (Опционально) Выходная переменная, которая покажет структуру хостов для инвентаря Ansible
# Этот output собирает данные в формат, удобный для написания inventory.yml
output "ansible_inventory_hosts" {
  description = "Structured data suitable for generating Ansible inventory"
  value = {
    for env_name, env_module_output in module.environment_servers : env_name => { # Итерация по модулям для создания ключей карты (env_name)
      hosts = { # Внутри каждого контура создаем карту хостов
        for ip in env_module_output.container_ips : # Итерация по IP внутри среды для создания ключей карты hosts
        ip => { # Ключ хоста в инвентаре - сам IP адрес. Значение - атрибуты хоста.
          ansible_user = var.ssh_user
          # НЕ ВЫВОДИТЕ СЕКРЕТЫ В OUTPUTS! Пароль должен обрабатываться Ansible Vault или ключами.
          # ansible_password = var.ssh_password
        }
      }
    }
  }
}
*/ # <--- Конец многострочного комментария
