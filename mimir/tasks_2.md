# Продолжаем установку Mimir в разрезе мониторинга

## Раздел переедет в репозиторий Docker, пока не выполняем

_Пользуемся официальной документацией на GitHub (в основном там прописаны Docker файлы на запуск и всегда есть конфиги)_

[Рабочий конфиг для контейнера и успешный запуск Mimir](https://github.com/grafana/mimir/blob/main/docs/sources/mimir/get-started/_index.md)

## Tasks 2

- Требуется вывести три инстанса `Mimir` в [кольцо хэшринга](https://grafana.com/docs/mimir/latest/references/architecture/hash-ring/) (это горизонтальное масштабирование)
- Успешный хэшринг будет выглядеть вот так (будет доступен по ссылке `Memberlist Status`):
    
    | Memberlist Cluster Members |               |        |
    |----------------------------|---------------|--------|
    | **Name**                   | **Address**   | **State** |
    | debian-2f01f116            | 10.49.71.205:7946 | 🟢 Alive  |
    | debian-4ce0a848            | 10.49.71.206:7946 | 🟢 Alive  |
    | debian-b1a9343d            | 10.49.71.167:7946 | 🟢 Alive  |
