# Настройки всех сред (dev, staging, prod) в одной переменной типа map(object)
variable "environments" {
  description = "Configurations for all environments"
  type = map(object({
    web_port    = number # Порт для веб-сервера (например, 8080)
    db_user     = string # Пользователь PostgreSQL
    db_password = string # Пароль PostgreSQL
  }))
}

