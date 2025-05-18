# modules/environment_servers/outputs.tf

# Выходная переменная, которая выставляет ресурсы server, созданные в этом модуле
# Поскольку ресурс "server" в main.tf модуля создан с count, эта output переменная будет СПИСКОМ.
output "server_containers" {
  description = "The server container resources created by this module instance"
  value       = docker_container.server
}

# (Опционально, если нужен список только IP-адресов из модуля)
# output "server_ips" {
#   description = "List of IP addresses of server containers created by this module instance"
#   value       = [for container in docker_container.server : container.ipv4_address]
# }
# modules/environment_servers/outputs.tf

# Output Variable: Список IP-адресов серверов, созданных этим модулем
# Эта выходная переменная будет доступна из корневого модуля.
# modules/environment_servers/outputs.tf

# Output Variable: Список IP-адресов серверов, созданных этим модулем
# Эта выходная переменная будет доступна из корневого модуля.
output "container_ips" {
  description = "List of IPs of server containers created in this environment"
  # Ресурс "docker_container.server" использует count, поэтому он возвращает список.
  # Мы проходим по этому списку и для каждого контейнера берем запрошенный ipv4_address
  # из первого элемента *networks_advanced*. networks_advanced - это set,
  # поэтому мы преобразуем его в list функцией tolist(), чтобы взять элемент по индексу [0].
  # networks_advanced[0].ipv4_address содержит запрошенный статический IP,
  # который известен во время plan.
  value = [
    for container in docker_container.server : tolist(container.networks_advanced)[0].ipv4_address
  ]
}
