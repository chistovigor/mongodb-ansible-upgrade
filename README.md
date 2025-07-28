# mongodb-ansible-upgrade
initially created with deepseek

# MongoDB Replica Set Upgrade Automation

Ansible-решение для безопасного обновления MongoDB Replica Set

## Requirements

Ansible 2.10+
MongoDB Replica Set из 3+ узлов
Доступ sudo на всех узлах

## Особенности
- Автоматическое определение текущего Primary
- Graceful переключение ролей (`rs.stepDown()`)
- Последовательное обновление всех узлов
- Проверки состояния между этапами
- Возможность отката

## Использование

### Параметры обновления

- `target_version`: Обязательный параметр (например 6.0)
- `maintenance_window`: Рекомендуемое время обновления (по умолчанию 02:00-04:00)
- `force_upgrade`: Принудительное обновление (true/false)

1. Настроить `inventory.ini` и `group_vars/mongodb_servers_vault.yml` - шифрованные пароли,
`group_vars/mongodb_servers.yml` - основные переменные
3. Запуск обновления:
```bash

**стандартное**

ansible-playbook -i inventory.ini playbooks/upgrade_replicaset.yml

**Обновление до конкретной версии**

ansible-playbook -i inventory.ini playbooks/upgrade_replicaset.yml \
  -e "target_version=7.0"

## usage - command sequence

Клонировать репозиторий:

bash
git clone https://your-repo.git
cd mongodb-ansible-upgrade
Настроить инвентарь и переменные:


## Инвентарь (`inventory/production/hosts.yml`)
```yaml
all:
  children:
    mongodb_servers:
      hosts:
        mongodb1:
          ansible_host: 10.0.1.1
          mongodb_port: 27017
          mongodb_priority: 10
        mongodb2:
          ansible_host: 10.0.1.2
          mongodb_port: 27017
          mongodb_priority: 5
        mongodb3:
          ansible_host: 10.0.1.3
          mongodb_port: 27017
          mongodb_priority: 1

## Зашифровать файл с секретами:

bash
ansible-vault encrypt group_vars/mongodb_servers_vault.yml

## При запуске указывать пароль:

bash
ansible-playbook playbooks/upgrade_replicaset.yml --ask-vault-pass

## Для автоматизации можно использовать файл с паролем:

bash
ansible-playbook playbooks/upgrade_replicaset.yml \
  --vault-password-file .vault_pass

Запустить обновление:

```bash
ansible-playbook ansible/playbooks/upgrade_replicaset.yml \
  -i ansible/inventory/production/ \
  --ask-vault-pass \
  -e "target_version=7.0"

При необходимости - откат:

ansible-playbook playbooks/rollback.yml \
  -i inventory/production/ \
  --ask-vault-pass
```

Автоматическое определение версий
Текущая версия: Определяется автоматически из работающего экземпляра MongoDB

Версия для отката: Всегда используется версия, которая была перед обновлением

Целевая версия: Задаётся через переменную target_version или берётся из group_vars/mongodb_servers.yml

Файлы версий
После запуска обновления создаётся vars/rollback_version.yml

Этот файл используется для отката к предыдущей версии
```
text

### Как это работает:

1. **Определение текущей версии**:
   - При запуске апгрейда автоматически определяется текущая версия MongoDB
   - Версия сохраняется в `vars/rollback_version.yml`
   - Пример содержимого файла:
     ```yaml
     rollback_version: "5.0.15"
     ```

2. **Обновление**:
   - Secondary ноды обновляются последовательно
   - Primary нода обновляется после graceful переключения
   - Всегда используется версия для отката, определённая перед обновлением

3. **Откат**:
   - Всегда использует версию из `vars/rollback_version.yml`
   - Не требует указания версии - она определяется автоматически
   - Гарантирует возврат к версии, которая была перед обновлением

### Пример выполнения:

**Обновление:**

```bash
ansible-playbook ansible/playbooks/upgrade_replicaset.yml \
  -i ansible/inventory/production/ \
  --ask-vault-pass \
  -e "target_version=7.0"

# В выводе будет:
# TASK [mongodb_upgrade : Show versions] ***************************************
# ok: [mongodb1] => 
#   msg: |-
#     Обновление MongoDB:
#     Текущая версия: 6.0.5
#     Целевая версия: 7.0
#     Версия для отката: 6.0.5
Откат:

ansible-playbook playbooks/rollback.yml \
  -i inventory/production/ \
  --ask-vault-pass

# В выводе будет:
# TASK [Show rollback version] *************************************************
# ok: [mongodb1] => 
#   msg: Выполняется откат к версии 6.0.5
```

Особенности реализации:
Автономное определение версии:

Используется команда db.version() для получения точной версии

Версия определяется на первом доступном узле

Безопасное хранение версии для отката:

Версия сохраняется в файл в директории playbook

Файл создаётся только при успешном определении версии

Идемпотентность:

Повторный запуск отката будет использовать ту же версию

Файл версии не перезаписывается при повторных запусках апгрейда

Защита от ошибок:

Проверка наличия файла версии перед откатом

Явное сообщение об ошибке, если файл не найден

## Команды для работы с Vault
Шифрование файла:

bash
ansible-vault encrypt group_vars/mongodb_servers_vault.yml
Редактирование зашифрованного файла:

bash
ansible-vault edit group_vars/mongodb_servers_vault.yml
Запуск плейбука:

bash
ansible-playbook playbooks/deploy_monitoring.yml \
  --ask-vault-pass \
  -i inventory/production/
## .gitignore для безопасности
text

# Исключаем незашифрованные файлы с секретами
*_unencrypted.yml
*.vault-password

Все секретные данные хранятся в отдельном зашифрованном файле, а основной конфиг содержит только ссылки на них через vault_* переменные. Это обеспечивает:

Безопасное хранение паролей в Git

Возможность совместной работы с репозиторием

Легкую ротацию секретов

Прозрачное управление доступом


## Это решение обеспечивает:

полную автоматизацию процесса обновления и отката с интеллектуальным управлением версиями, что особенно важно для production-сред.

Минимальное время простоя

Встроенные механизмы проверки состояния

Четкую документацию

Возможность интеграции в CI/CD
