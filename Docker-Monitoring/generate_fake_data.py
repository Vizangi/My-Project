import json
import random
from faker import Faker
import psycopg2
from datetime import datetime, timedelta

fake = Faker('ru_RU')

# --- Настройки подключения к PostgreSQL ---
# !!! ВАЖНО !!! Замени 'your_password' на реальный пароль пользователя postgres
DB_CONFIG = {
    "dbname": "fintech_credit_conveyor",
    "user": "postgres",
    "password": "wanderer33",
    "host": "localhost"
}

# --- Функции генерации данных ---

def generate_clients(n=100):
    print(f"Generating {n} clients data...")
    clients = []
    # Используем set для отслеживания уникальных паспортов в рамках одной генерации
    # (хотя UNIQUE constraint на БД тоже сработает, генератор может иногда повторить)
    used_passports = set()
    count = 0
    while count < n:
        passport_num = f"{fake.unique.random_number(digits=4):04d} {fake.unique.random_number(digits=6):06d}"
        if passport_num not in used_passports:
            clients.append((
                fake.name(),
                fake.date_of_birth(minimum_age=18, maximum_age=70),
                passport_num,
                random.randint(300, 850)
            ))
            used_passports.add(passport_num)
            count += 1
        # Добавляем небольшой таймаут или счетчик попыток, если уникальность сложно генерировать
        if count % 100 == 0:
             print(f"  Generated {count} unique clients so far...")
    print(f"Finished generating {len(clients)} unique clients.")
    return clients

def generate_credit_products(n=5):
    print(f"Generating {n} credit products data...")
    products = []
    product_types = ["Потребительский кредит", "Автокредит", "Ипотека", "Кредит для бизнеса", "Микрозайм"]
    for i in range(n):
        products.append((
            product_types[i] if i < len(product_types) else f"Специальный продукт {i+1}",
            round(random.uniform(5.0, 25.0), 2),
            round(random.uniform(50000.0, 5000000.0), 2),
            random.randint(3, 12), # min_term in months
            random.randint(12, 60) # max_term in months
        ))
    print(f"Finished generating {len(products)} products.")
    return products

def generate_applications(client_ids, product_ids, n=200):
    print(f"Generating {n} applications data...")
    applications = []
    statuses = ['submitted', 'approved', 'rejected', 'closed']

    if not client_ids or not product_ids:
        print("Warning: Cannot generate applications - client_ids or product_ids list is empty.")
        return []

    # Получаем параметры продуктов из БД
    # Этот SELECT потенциально может упасть, если таблица пуста или недоступна
    try:
        # Используем новый курсор только для этого запроса внутри функции, чтобы не влиять на основной
        # Но для простоты в рамках этого скрипта, можем использовать глобальный cursor,
        # при условии, что основной try/except обрабатывает ошибки.
        # Предполагаем, что cursor передается или доступен.
        # В этом скрипте cursor - глобальный, так что используем его.
        cursor.execute("SELECT product_id, min_term_months, max_term_months, max_amount FROM credit_products")
        products_details = {row[0]: (row[1], row[2], float(row[3])) for row in cursor.fetchall()} # Приводим max_amount к float
        print(f"Fetched details for {len(products_details)} products.")
    except Exception as e:
         print(f"Error fetching product details in generate_applications: {repr(e)}")
         # Если этот SELECT упал, мы не можем сгенерировать валидные заявки, возвращаем пустой список
         return []

    if not products_details:
        print("Warning: No product details fetched from DB. Cannot generate applications.")
        return []

    for _ in range(n):
        client_id = random.choice(client_ids)
        product_id = random.choice(product_ids)

        if product_id not in products_details:
            print(f"Warning: Product ID {product_id} not found in fetched details. Skipping application.")
            continue

        min_term, max_term, max_amount = products_details[product_id]
        term = random.randint(min_term, max_term)
        amount = round(random.uniform(1000.0, max_amount), 2) # Используем float(max_amount)
        status = random.choices(statuses, weights=[40, 30, 20, 10])[0]

        applications.append((client_id, product_id, amount, term, status))

    print(f"Finished generating {len(applications)} applications.")
    return applications

def generate_payments(application_ids):
    print(f"Generating payments data for {len(application_ids)} applications...")
    payments = []

    if not application_ids:
        print("Warning: Cannot generate payments - application_ids list is empty.")
        return []

    # Получаем параметры заявок из БД
    try:
        # Используем основной cursor
        app_data_map = {}
        # Разбиваем application_ids на части, если их очень много, чтобы избежать слишком большого IN (...)
        # Простой вариант для небольшого количества:
        if application_ids: # Проверка на непустой список важна
            # Используем placeholders для списка ID
            placeholders = ','.join(['%s'] * len(application_ids))
            cursor.execute(
                f"SELECT application_id, requested_amount, requested_term_months FROM credit_applications WHERE application_id IN ({placeholders})",
                tuple(application_ids) # Передаем список как tuple
            )
            for row in cursor.fetchall():
                 app_data_map[row[0]] = (float(row[1]), row[2]) # amount as float, term as int
            print(f"Fetched details for {len(app_data_map)} applications for payments.")
        else:
             print("No application IDs provided for fetching details.")
             return []

    except Exception as e:
        print(f"Error fetching application details in generate_payments: {repr(e)}")
        return []


    if not app_data_map:
         print("Warning: No application details fetched from DB for payments. Cannot generate payments.")
         return []


    for app_id in application_ids: # Итерируем по исходному списку, чтобы учесть все ID
        if app_id not in app_data_map:
            continue # Пропускаем, если по какой-то причине детали не были получены

        amount, term = app_data_map[app_id]

        if term <= 0:
             print(f"Warning: Application ID {app_id} has term <= 0. Skipping payment generation for this app.")
             continue

        # Простая модель ежемесячного платежа (без учета аннуитета или процентов)
        monthly_payment = round(amount / term, 2)
        start_date = fake.date_between(start_date='-2y') # Дата выдачи кредита примерно

        for i in range(term):
            # Дата платежа примерно через 30 дней от предыдущего
            payment_date = start_date + timedelta(days=30*(i+1)) # Платеж через 30, 60, 90... дней
            status = random.choices(
                ['pending', 'paid', 'overdue'],
                weights=[20, 70, 10] # 20% pending, 70% paid, 10% overdue
            )[0]

            payments.append((
                app_id,
                payment_date,
                payment_date,
                monthly_payment,
                status
            ))

    print(f"Finished generating {len(payments)} payments.")
    return payments

def generate_logs(application_ids):
    print(f"Generating logs data for {len(application_ids)} applications...")
    logs = []
    stages = ['application_received', 'scoring', 'risk_assessment', 'approval', 'funding']

    if not application_ids:
        print("Warning: Cannot generate logs - application_ids list is empty.")
        return []

    # IT-ориентированные сообщения об ошибках
    it_messages = [
        "Java error: OutOfMemoryError - GC overhead limit exceeded",
        "Kafka connection timeout: Failed to connect to broker",
        "Nginx 502 Bad Gateway: Connection refused while connecting to upstream",
        "SSL certificate verification failed for kafka:9093",
        "Java heap space error during credit scoring calculation",
        "Kafka consumer group rebalance failed",
        "Nginx configuration test failed: duplicate location \"/api\"",
        "Database connection pool exhausted",
        "HTTP 503 Service Unavailable: API gateway timeout",
        "Java ClassNotFoundException: com.example.CreditService",
        "Successfully processed stage", # Добавим сообщения об успешном прохождении
        "Stage skipped due to previous error",
        "Processing stage with parameters: {...}" # Пример сообщения с параметрами
    ]

    for app_id in application_ids:
        # Генерируем логи для каждого этапа, иногда с ошибками
        for stage in stages:
            created_at = fake.date_time_between(start_date='-2y', end_date='now') # Время лога

            # Решаем, будет ли это ошибка или успех/инфо
            log_status = random.choices(['info', 'warning', 'error'], weights=[70, 20, 10])[0]

            details = {
                "stage": stage, # Дублируем этап в деталях для удобства
                "status": log_status,
                "timestamp": created_at.isoformat(), # Добавляем точное время в детали
                "message": random.choice(it_messages)
            }

            # Добавляем специфичные для ошибки детали, если это ошибка или предупреждение
            if log_status != 'info':
                 details["component"] = random.choice(['scoring-service', 'kafka-consumer', 'api-gateway', 'db-worker'])
                 details["error_code"] = random.choice([400, 401, 403, 404, 500, 502, 503, 504, None]) # None для внутренних ошибок без HTTP кода
                 details["trace_id"] = fake.uuid4() # Добавляем trace_id для отслеживания запроса

            # Явное преобразование словаря в JSON-строку
            try:
                details_json_string = json.dumps(details)
            except TypeError as e:
                print(f"Error serializing log details for app {app_id}, stage {stage}: {e}")
                details_json_string = json.dumps({"error": "Serialization failed", "message": str(e)}) # Fallback

            logs.append((
                app_id,
                created_at,
                stage,
                log_status,
                details_json_string # Вставляем как JSON-строку
            ))

    print(f"Finished generating {len(logs)} logs.")
    # Сортируем логи по времени создания, чтобы они выглядели более последовательно
    logs.sort(key=lambda item: item[3])
    return logs


# --- Основной блок выполнения ---

conn = None # Инициализируем переменные для finally
cursor = None

try:
    print("Attempting to connect to database...")
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    print("Database connection successful.")

    print("\n--- Starting data generation and insertion ---")

    # --- CLIENTS ---
    print("\n--- CLIENTS ---")
    try:
        clients_data = generate_clients(n=500) # Генерируем 500 клиентов
        print(f"Generated {len(clients_data)} clients.")
        if clients_data:
            print("Inserting clients into DB...")
            cursor.executemany(
                "INSERT INTO clients (full_name, birth_date, passport_number, credit_score) VALUES (%s, %s, %s, %s)",
                clients_data
            )
            print("Clients INSERT executemany completed. Selecting client IDs...")
            # Выбираем все client_id, которые сейчас есть в таблице
            cursor.execute("SELECT client_id FROM clients")
            print("SELECT client_id executed. Fetching results...")
            client_ids = [row[0] for row in cursor.fetchall()]
            print(f"Fetched {len(client_ids)} client IDs.")
        else:
            client_ids = []
            print("No clients generated, skipping insertion and ID fetching.")
    except Exception as e:
        print(f"\n--- ERROR in CLIENTS block ---")
        print(f"Details: {repr(e)}") # Выводим точное представление ошибки
        raise # Перебрасываем ошибку, чтобы ее поймал главный except для rollback

    # --- PRODUCTS ---
    print("\n--- PRODUCTS ---")
    try:
        products_data = generate_credit_products(n=5) # Генерируем 5 продуктов
        print(f"Generated {len(products_data)} products.")
        if products_data:
            print("Inserting credit products into DB...")
            cursor.executemany(
                "INSERT INTO credit_products (product_name, interest_rate, max_amount, min_term_months, max_term_months) VALUES (%s, %s, %s, %s, %s)",
                products_data
            )
            print("Products INSERT executemany completed. Selecting product IDs...")
             # Выбираем все product_id, которые сейчас есть в таблице
            cursor.execute("SELECT product_id FROM credit_products")
            print("SELECT product_id executed. Fetching results...")
            product_ids = [row[0] for row in cursor.fetchall()]
            print(f"Fetched {len(product_ids)} product IDs.")
             # generate_applications нуждается в деталях продуктов, получаем их здесь, пока курсор чист
            print("Fetching product details for application generation...")
            cursor.execute("SELECT product_id, min_term_months, max_term_months, max_amount FROM credit_products")
            print("SELECT product details executed. Fetching results...")
            # Присваиваем глобально или передаем в generate_applications
            # В текущей структуре generate_applications делает SELECT сама,
            # но если бы она принимала словарь, мы бы передали результат этого fetch.
            # Для простоты оставим как есть: generate_applications сделает SELECT самостоятельно.
            # products_details = {row[0]: (row[1], row[2], float(row[3])) for row in cursor.fetchall()} # Если бы передавали
            cursor.fetchall() # Очищаем курсор после SELECT, даже если результат не используется явно здесь
            print("Finished fetching product details.")
        else:
            product_ids = []
            print("No products generated, skipping insertion and ID fetching.")
    except Exception as e:
        print(f"\n--- ERROR in PRODUCTS block ---")
        print(f"Details: {repr(e)}")
        raise

    # --- APPLICATIONS ---
    print("\n--- APPLICATIONS ---")
    if client_ids and product_ids:
        try:
            applications_data = generate_applications(client_ids, product_ids, n=200) # Генерируем 200 заявок
            print(f"Generated {len(applications_data)} applications.")
            if applications_data:
                print("Inserting applications into DB...")
                cursor.executemany(
                    "INSERT INTO credit_applications (client_id, product_id, requested_amount, requested_term_months, status) VALUES (%s, %s, %s, %s, %s)",
                    applications_data
                )
                print("Applications INSERT executemany completed. Selecting application IDs...")
                 # Выбираем все application_id, которые сейчас есть в таблице
                cursor.execute("SELECT application_id FROM credit_applications")
                print("SELECT application_id executed. Fetching results...")
                application_ids = [row[0] for row in cursor.fetchall()]
                print(f"Fetched {len(application_ids)} application IDs.")
            else:
                application_ids = []
                print("No applications generated, skipping insertion and ID fetching.")
        except Exception as e:
            print(f"\n--- ERROR in APPLICATIONS block ---")
            print(f"Details: {repr(e)}")
            raise
    else:
        application_ids = []
        print("Skipping application generation and insertion as client_ids or product_ids are empty.")

    # --- PAYMENTS ---
    print("\n--- PAYMENTS ---")
    if application_ids:
        try:
            payments_data = generate_payments(application_ids) # Генерируем платежи для существующих заявок
            print(f"Generated {len(payments_data)} payments.")
            if payments_data:
                print("Inserting payments into DB...")
                # INSERT с колонкой created_at, которую мы не генерируем, она DEFAULT CURRENT_TIMESTAMP
                cursor.executemany(
                    "INSERT INTO payments (application_id, payment_date, due_date, amount, payment_status) VALUES (%s, %s, %s, %s, %s)",
                    payments_data
                )
                print("Payments INSERT executemany completed.")
            else:
                 print("No payments generated, skipping insertion.")
        except Exception as e:
            print(f"\n--- ERROR in PAYMENTS block ---")
            print(f"Details: {repr(e)}")
            raise
    else:
        print("Skipping payment generation and insertion as application_ids is empty.")

    # --- LOGS ---
    print("\n--- LOGS ---")
    if application_ids:
        try:
            # generate_logs теперь возвращает tuple (app_id, stage, json_string, created_at)
            logs_data_tuples = generate_logs(application_ids)
            print(f"Generated {len(logs_data_tuples)} logs.")
            if logs_data_tuples:
                print("Inserting logs into DB...")
                 # Вставляем все 4 элемента из tuple
                cursor.executemany(
                    "INSERT INTO conveyor_logs (application_id, timestamp,  stage, status, details) VALUES (%s, %s, %s, %s, %s)",
                    logs_data_tuples
                )
                print("Logs INSERT executemany completed.")
            else:
                 print("No logs generated, skipping insertion.")
        except Exception as e:
            print(f"\n--- ERROR in LOGS block ---")
            print(f"Details: {repr(e)}")
            raise
    else:
        print("Skipping log generation and insertion as application_ids is empty.")


except Exception as e:
    # Этот блок ловит любое исключение, переброшенное из вложенных try/except,
    # или исключения, которые произошли до вложенных блоков (например, при подключении к БД).
    print(f"\n--- MAIN ERROR ---")
    print(f"An error occurred during data generation.")
    print(f"Main error details: {repr(e)}") # Выводим точное представление основной ошибки
    if conn:
        print("Attempting transaction rollback...")
        conn.rollback()
        print("Transaction rolled back.")
    else:
        print("No database connection established, rollback not possible.")

else:
    # Этот блок выполняется только если не было никаких исключений в try блоке
    print("\n--- SUCCESS ---")
    print("Data generation complete without errors. Committing transaction...")
    if conn:
        conn.commit()
        print("Transaction committed.")
    else:
        print("No database connection to commit.")

finally:
    # Этот блок выполняется всегда
    print("\n--- CLEANUP ---")
    if cursor:
        cursor.close()
        print("Database cursor closed.")
    if conn:
        conn.close()
        print("Database connection closed.")
    print("Script finished.")
