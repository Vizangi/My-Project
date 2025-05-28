# Проект: Credit Conveyor Monitoring

Наблюдение за кредитным конвейером с помощью Prometheus + Grafana. Автоматизация развёртывания через Terraform, Ansible и Docker.

## 🧩 Stack
- **Terraform** — развёртывание инфраструктуры
- **Ansible** — конфигурация окружения
- **Docker Compose** — запуск Prometheus, Grafana, Alertmanager, node_exporter и др.
- **Prometheus** — сбор метрик
- **Grafana** — дашборды
- **Alertmanager** — алёрты

## 🚀 Быстрый старт

```bash
git clone https://github.com/Vizangi/My-Project/
cd credit-monitoring

# 1. Разворачиваем инфраструктуру
terraform init && terraform apply

# 2. Конфигурируем окружение
ansible-playbook -i inventory setup.yml

# 3. Запускаем мониторинг
docker-compose up -d
