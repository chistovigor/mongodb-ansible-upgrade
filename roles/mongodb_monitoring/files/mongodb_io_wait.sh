#!/bin/bash
# Расчет I/O Wait для MongoDB (в процентах)
# Параметры: $1 - хост, $2 - порт, $3 - кластер

HOST=${1:-localhost}
PORT=${2:-27017}
CLUSTER=${3}
LOG_FILE="/var/log/zabbix/mongodb_io_wait.log"

# Настройки аутентификации
if [ -f /etc/zabbix/mongodb_creds.conf ]; then
  source /etc/zabbix/mongodb_creds.conf
  AUTH="--username $MONGO_USER --password $MONGO_PASS --authenticationDatabase admin"
else
  AUTH=""
fi

# Логирование ошибок
exec 2>>$LOG_FILE

# Основной запрос
IO_WAIT=$(mongo --host $HOST --port $PORT $AUTH --quiet --eval "
try {
  var status = db.serverStatus();
  var ioWait = 0;
  
  if (status.metrics && status.metrics.operation) {
    var op = status.metrics.operation;
    var locked = op.timeLockedMicros.r || 0;
    var executing = op.timeExecutingMicros.r || 0;
    var total = locked + executing;
    ioWait = total > 0 ? ((locked / total) * 100) : 0;
  }
  
  print(Math.round(ioWait * 100) / 100); // Округление до 2 знаков
} catch(e) {
  print(-1); // Код ошибки
  print('ERROR: ' + e); // В stderr
}" | tee -a $LOG_FILE | head -1)

# Валидация результата
if ! [[ "$IO_WAIT" =~ ^[0-9.]+$ ]]; then
  echo 0
  echo "Invalid IO_WAIT value: $IO_WAIT" >> $LOG_FILE
else
  echo $IO_WAIT
fi
