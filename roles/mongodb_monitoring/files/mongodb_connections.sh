#!/bin/bash
# Скрипт проверки текущих подключений к MongoDB
# Параметры: $1 - хост, $2 - порт

HOST=${1:-localhost}
PORT=${2:-27017}
LOG_FILE="/var/log/zabbix/mongodb_connections.log"

# Аутентификация
if [ -f /etc/zabbix/mongodb_creds.conf ]; then
    source /etc/zabbix/mongodb_creds.conf
    AUTH="--username $MONGO_USER --password $MONGO_PASS --authenticationDatabase admin"
else
    AUTH=""
fi

# Логирование ошибок
exec 2>>$LOG_FILE

# Получение метрик
CONNECTIONS=$(mongo --host $HOST --port $PORT $AUTH --quiet --eval "
try {
    var status = db.serverStatus();
    var connections = status.connections || {};
    var memory = status.mem || {};
    var network = status.network || {};
    
    printjson({
        ok: 1,
        current: connections.current || 0,
        available: connections.available || 0,
        totalCreated: connections.totalCreated || 0,
        active: connections.active || 0,
        readers: connections.readers || 0,
        writers: connections.writers || 0,
        memoryMb: (memory.resident || 0) / 1024 / 1024,
        networkIn: (network.bytesIn || 0) / 1024 / 1024,
        networkOut: (network.bytesOut || 0) / 1024 / 1024
    });
} catch (e) {
    printjson({
        ok: 0,
        error: e.toString(),
        current: 0,
        available: 0
    });
}
")

# Форматирование вывода
echo "$CONNECTIONS" | jq -c . 2>/dev/null || echo '{"ok":0,"error":"jq_parse_failed"}'
