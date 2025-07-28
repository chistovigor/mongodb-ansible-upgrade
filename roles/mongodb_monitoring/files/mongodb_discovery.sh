#!/bin/bash
# Обнаружение MongoDB инстансов на сервере с поддержкой Replica Set
# Формат вывода для Zabbix LLD

CONFIG_FILES=$(ls /etc/mongod*.conf 2>/dev/null)
[ -z "$CONFIG_FILES" ] && echo '{"data":[]}' && exit 0

RESULT='{"data":['
for CONF in $CONFIG_FILES; do
  PORT=$(grep -E '^[[:space:]]*port[[:space:]]*=[[:space:]]*' $CONF | awk '{print $3}')
  PORT=${PORT:-27017}
  CLUSTER=$(grep -E '^[[:space:]]*replSetName[[:space:]]*=[[:space:]]*' $CONF | awk '{print $3}')
  CLUSTER=${CLUSTER:-standalone}
  HOST=$(hostname -f 2>/dev/null || hostname)
  
  # Получаем credentials если есть
  if [ -f /etc/zabbix/mongodb_creds.conf ]; then
    source /etc/zabbix/mongodb_creds.conf
    AUTH="--username $MONGO_USER --password $MONGO_PASS --authenticationDatabase admin"
  else
    AUTH=""
  fi

  # Проверяем тип инстанса
  INSTANCE_TYPE="secondary"
  if [ "$CLUSTER" != "standalone" ]; then
    IS_MASTER=$(mongo --host $HOST --port $PORT $AUTH --quiet --eval 'rs.isMaster().ismaster' 2>/dev/null)
    [ "$IS_MASTER" = "true" ] && INSTANCE_TYPE="primary"
  else
    INSTANCE_TYPE="standalone"
  fi

  RESULT+="{\"{#MONGODBHOST}\":\"$HOST\", \"{#MONGODBPORT}\":\"$PORT\", \"{#MONGODBCLUSTER}\":\"$CLUSTER\", \"{#INSTANCETYPE}\":\"$INSTANCE_TYPE\"},"
done

echo "${RESULT%,}]}"
