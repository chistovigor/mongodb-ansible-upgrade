#!/bin/bash
# Скрипт проверки статуса репликации MongoDB
# Возвращает JSON с ключевыми метриками

HOST=${1:-localhost}
PORT=${2:-27017}
LOG_FILE="/var/log/zabbix/mongodb_repl_status.log"

# Аутентификация (если есть файл creds)
if [ -f /etc/zabbix/mongodb_creds.conf ]; then
    source /etc/zabbix/mongodb_creds.conf
    AUTH="--username $MONGO_USER --password $MONGO_PASS --authenticationDatabase admin"
else
    AUTH=""
fi

# Логирование ошибок
exec 2>>$LOG_FILE

# Основная проверка
STATUS=$(mongo --host $HOST --port $PORT $AUTH --quiet --eval "
function toISODateString(date) {
    return date ? date.toISOString() : null;
}

try {
    var status = rs.status();
    var isMaster = db.isMaster();
    var health = 1; // 1 = OK, 0 = Error
    
    // Проверка для PRIMARY
    if (isMaster.ismaster) {
        printjson({
            ok: 1,
            stateStr: 'PRIMARY',
            optimeDate: toISODateString(status.members.find(m => m.state === 1).optimeDate),
            members: status.members.map(m => ({
                name: m.name,
                stateStr: m.stateStr,
                lag: m.optimeDate ? 
                    new Date() - m.optimeDate : null,
                health: m.health
            })),
            health: health
        });
    } 
    // Проверка для SECONDARY
    else {
        var primary = status.members.find(m => m.state === 1);
        var self = status.members.find(m => m.self);
        
        printjson({
            ok: 1,
            stateStr: self.stateStr,
            syncLag: primary ? 
                (self.optimeDate - primary.optimeDate) / 1000 : null,
            lastHeartbeat: toISODateString(self.lastHeartbeat),
            pingMs: self.lastHeartbeatMs,
            health: health
        });
    }
} catch (e) {
    printjson({
        ok: 0,
        error: e.toString(),
        health: 0
    });
}
")

# Форматирование вывода для Zabbix
echo "$STATUS" | jq -c . 2>/dev/null || echo '{"ok":0,"error":"jq_parse_failed"}'
