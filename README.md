# Проект: Credit Conveyor Monitoring


## Быстрый старт

```bash
# Credit Conveyor Monitoring

Мониторинг кредитного конвейера с помощью Prometheus, Grafana, Alertmanager. Инфраструктура разворачивается через Terraform, настраивается через Ansible, сервисы контейнеризованы в Docker.

##  Стек

- **Terraform** — инфраструктура (VM, сеть)
- **Ansible** — автоматизация установки экспортеров
- **Docker Compose** — Prometheus, Grafana, Alertmanager, Node Exporter, nginx
- **Экспортеры** — process_exporter, node_exporter и др.
- **Fake Data Generator** — Python-скрипт `generate_fake_data.py`

---

## 📦 Структура проекта

<details>
<summary><code>Task4-AnsibleInfra/</code> — Terraform</summary>

- `main.tf`, `variables.tf`, `terraform.tfvars` — определение и вызов модулей
- `modules/environment_servers/` — шаблон окружения (VM, сеть)
</details>

<details>
<summary><code>Ansible-Monitoring/</code> — Ansible</summary>

- `playbook.yml` — главный Playbook
- `roles/process_exporter/` — установка и запуск exporter'а
- `inventories/hosts.yml`, `vars/`, `ansible.cfg` — окружение и конфигурация
</details>

<details>
<summary><code>Docker-Monitoring/</code> — Docker + мониторинг</summary>

- `docker-compose.yml` — стек мониторинга
- `prometheus.yml`, `alertmanager.yml`, `nginx.conf` — конфиги
- `grafana-dockerfile` и др. — кастомные образы
- `generate_fake_data.py` — симуляция данных
</details>

---

## 🚀 Быстрый старт

```bash
# 1. Разворачиваем инфраструктуру
cd Task4-AnsibleInfra
terraform init && terraform apply

# 2. Настраиваем сервера
cd ../Ansible-Monitoring
ansible-playbook -i inventories/hosts.yml playbook.yml

# 3. Запускаем мониторинг
cd ../Docker-Monitoring
docker-compose up -d
```


## 📊 Метрики и Алерты
Нагрузка CPU / память (Node Exporter)

Активные процессы (Process Exporter)

Кастомные SQL-запросы к базе

Алерты через Alertmanager (примеры в alertmanager.yml)


## 🛠 TODO

- [ ] Добавить Blackbox Exporter для проверки доступности API
- [ ] Автоматизировать настройку Grafana dashboard через JSON API
- [ ] Добавить алерт при падении process_exporter
- [ ] Интеграция Slack / Telegram для алертов
