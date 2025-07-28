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

1. Настроить `inventory.ini` и `group_vars/all.yml`
2. Запуск обновления:
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

bash
nano inventory.ini
nano group_vars/all.yml
Запустить обновление:

bash
ansible-playbook -i inventory.ini playbooks/upgrade_replicaset.yml

or

bash
ansible-playbook -i inventory.ini playbooks/upgrade_replicaset.yml \
  -e "target_version=7.0"

При необходимости - откат:

bash
ansible-playbook -i inventory.ini playbooks/rollback.yml
```

Автоматическое определение версий
Текущая версия: Определяется автоматически из работающего экземпляра MongoDB

Версия для отката: Всегда используется версия, которая была перед обновлением

Целевая версия: Задаётся через переменную target_version или берётся из group_vars/all.yml

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
ansible-playbook -i inventory.ini playbooks/upgrade_replicaset.yml \
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

bash
ansible-playbook -i inventory.ini playbooks/rollback.yml

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
