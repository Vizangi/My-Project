variable "environments" {
  description = "Configurations for all environments"
  type = map(object({
    subnet_prefix = string # Например, "172.25.0"
    server_count  = number # Количество серверов в контуре
  }))
}

# Переменные для доступа по SSH (для Ansible)
variable "ssh_user" {
 description = "Username for SSH access on server containers"
 type        = string
}

variable "ssh_password" {
  description = "Password for SSH access on server containers"
  type        = string
  sensitive   = true  # Чувствительные данные, в логах не будут выводиться
}
