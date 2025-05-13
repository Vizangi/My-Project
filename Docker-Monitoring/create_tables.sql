-- create_tables.sql

-- Таблица Клиенты
CREATE TABLE IF NOT EXISTS clients (
    client_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    passport_number VARCHAR(20) UNIQUE,
    date_of_birth DATE,
    address TEXT,
    phone_number VARCHAR(20),
    email VARCHAR(255) UNIQUE,
    credit_score INTEGER, -- Пример: кредитная история в виде числа
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Таблица Кредитные продукты
CREATE TABLE IF NOT EXISTS credit_products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL UNIQUE,
    interest_rate NUMERIC(5, 2) NOT NULL, -- Ставка процента
    min_amount NUMERIC(15, 2),
    max_amount NUMERIC(15, 2),
    min_term_months INTEGER,
    max_term_months INTEGER,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Таблица Заявки на кредит
CREATE TABLE IF NOT EXISTS credit_applications (
    application_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES clients(client_id),
    product_id INTEGER NOT NULL REFERENCES credit_products(product_id),
    application_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    requested_amount NUMERIC(15, 2) NOT NULL,
    requested_term_months INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending', -- Статусы: Pending, Approved, Rejected, Cancelled и т.д.
    decision_date TIMESTAMP WITH TIME ZONE,
    approved_amount NUMERIC(15, 2),
    approved_term_months INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Индекс для ускорения поиска заявок по клиенту или продукту
CREATE INDEX IF NOT EXISTS idx_applications_client_id ON credit_applications(client_id);
CREATE INDEX IF NOT EXISTS idx_applications_product_id ON credit_applications(product_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON credit_applications(status);

-- Таблица Платежи
CREATE TABLE IF NOT EXISTS payments (
    payment_id SERIAL PRIMARY KEY,
    application_id INTEGER NOT NULL REFERENCES credit_applications(application_id), -- Платеж связан с конкретной заявкой/кредитом
    payment_date DATE NOT NULL,
    due_date DATE NOT NULL, -- Плановая дата платежа
    amount NUMERIC(15, 2) NOT NULL,
    payment_status VARCHAR(50) NOT NULL DEFAULT 'Due', -- Статусы: Due, Paid, Overdue
    paid_at TIMESTAMP WITH TIME ZONE, -- Фактическое время платежа
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Индекс для ускорения поиска платежей по заявке
CREATE INDEX IF NOT EXISTS idx_payments_application_id ON payments(application_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(payment_status);

-- Таблица Кредитный конвейер (логирование этапов обработки заявок)
CREATE TABLE IF NOT EXISTS conveyor_logs (
    log_id SERIAL PRIMARY KEY,
    application_id INTEGER NOT NULL REFERENCES credit_applications(application_id),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    stage VARCHAR(100) NOT NULL, -- Этап конвейера (например, Scoring, Verification, Approval)
    status VARCHAR(50) NOT NULL, -- Статус на этапе (например, Success, Failure)
    details TEXT, -- Дополнительные детали или ошибки
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Индекс для ускорения поиска логов по заявке
CREATE INDEX IF NOT EXISTS idx_conveyor_logs_application_id ON conveyor_logs(application_id);
