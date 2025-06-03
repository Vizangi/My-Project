# Проект: Credit Conveyor Monitoring

Мониторинг кредитного конвейера с помощью Prometheus, Grafana, Alertmanager. Инфраструктура разворачивается через Terraform, настраивается через Ansible, сервисы контейнеризованы в Docker.

##  Стек

- Terraform 
- Ansible
- Docker Compose 
- Экспортеры
- Fake Data Generator

---

## Структура проекта

<details>
<summary><code>Task4-AnsibleInfra/</code> — Terraform</summary>

- `main.tf`, `variables.tf`, `terraform.tfvars` — определение и вызов модулей
- `modules/environment_servers/` — шаблон окружения (VM, сеть)

```
Task4-AnsibleInfra/ 
├── main.tf          <- Главный файл, вызывает модули
├── variables.tf     <- Определяет переменные, их типы и описания
├── terraform.tfvars <- Задает КОНКРЕТНЫЕ значения для переменных
├── modules/
│   └── environment_servers/
│       ├── main.tf  <- Ресурсы для ОДНОЙ среды (сети+серверы)
│       └── variables.tf <- Входные переменные модуля
└── terraform.tfstate <- Файл состояния (создается после apply), ЗНАЕТ о развернутой инфре
```
</details>

<details>
<summary><code>Ansible-Monitoring/</code> — Ansible</summary>

- `playbook.yml` — главный Playbook
- `roles/process_exporter/` — установка и запуск exporter'а
- `inventories/hosts.yml`, `vars/`, `ansible.cfg` — окружение и конфигурация

```
Ansible-Monitoring/
├── playbook.yml      <- Главный файл, определяет Play и вызывает роли
├── inventories/
│   └── hosts.yml     <- Список управляемых хостов и их группировка
├── roles/
│   └── process_exporter/
│       ├── tasks/
│       │   └── main.yml <- Задачи роли (установка, проверка, запуск)
│       ├── defaults/
│       │   └── main.yml <- Значения переменных по умолчанию
│       ├── templates/
│       │   └── process_exporter.service.j2 <- Шаблон unit файла
│       ├── handlers/
│       │   └── main.yml <- Обработчики (запускаются по notify)
│       └── ... другие подкаталоги роли
├── vars/             <- Каталог переменных (например, global.yml)
└── ansible.cfg       <- Общие настройки Ansible
```
</details>

<details>
<summary><code>Docker-Monitoring/</code> — Docker + мониторинг</summary>

- `docker-compose.yml` — стек мониторинга
- `prometheus.yml`, `alertmanager.yml`, `nginx.conf` — конфиги
- `grafana-dockerfile` и др. — кастомные образы
- `generate_fake_data.py` — симуляция данных
</details>

---

## Старт

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


##  Метрики и Алерты
Нагрузка CPU / память (Node Exporter)

Активные процессы (Process Exporter)

Кастомные SQL-запросы к базе

Алерты через Alertmanager (примеры в alertmanager.yml)


##  TODO

- [ ] Добавить Blackbox Exporter для проверки доступности API
- [ ] Автоматизировать настройку Grafana dashboard через JSON API
- [ ] Добавить алерт при падении process_exporter
- [ ] Интеграция Slack / Telegram для алертов


## Структура
```
Terraform:

Task4-AnsibleInfra/ 
├── main.tf          <- Главный файл, вызывает модули
├── variables.tf     <- Определяет переменные, их типы и описания
├── terraform.tfvars <- Задает значения для переменных
├── modules/
│   └── environment_servers/
│       ├── main.tf  <- Ресурсы для одной среды (сети+серверы)
│       └── variables.tf <- Входные переменные модуля
└── terraform.tfstate <- Файл состояния (создается после apply)


Ansible:

Ansible-Monitoring/
├── playbook.yml      <- Главный файл, определяет Play и вызывает роли
├── inventories/
│   └── hosts.yml     <- Список управляемых хостов и их группировка
├── roles/
│   └── process_exporter/
│       ├── tasks/
│       │   └── main.yml <- Задачи роли (установка, проверка, запуск)
│       ├── defaults/
│       │   └── main.yml <- Значения переменных по умолчанию
│       ├── templates/
│       │   └── process_exporter.service.j2 <- Шаблон unit файла
│       ├── handlers/
│       │   └── main.yml <- Обработчики (запускаются по notify)
│       └── ... другие подкаталоги роли
├── vars/             <- Каталог переменных (например, global.yml)
└── ansible.cfg       <- Общие настройки Ansible


Docker:

Docker-Monitoring/ 
├── monitoring-stack 
│     ├──grafana-dockerfile
│     ├──node-exp-dockerfile
│     ├──prometheus-dockerfile
│     ├──prometheus.yml
├── alermanager.yml  
├── create_tables.sql  

├── docker-compose.yml 
├── generate_fake_data.py
├── nginx.conf
└── queries.yml
