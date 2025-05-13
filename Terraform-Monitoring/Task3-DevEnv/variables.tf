# Порт, на котором будет доступен веб-сервер (например, http://localhost:8080)
variable "web_port" {
  description = "External port for web server"
  type        = number
  default     = 8080
}

# Список пользователей для PostfreSQL. Каждый элемент списка - объект
# с атрибутами 'username' и 'password'
variable "db_users" {
  description = "List of PostgreSQL users"
  type        = list(object({
    username = string
    password = string
  }))
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "dev_db" # Оставим пока default
}
