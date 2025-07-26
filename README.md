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
ansible-playbook -i inventory.ini playbooks/upgrade_replicaset.yml

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
При необходимости - откат:

bash
ansible-playbook -i inventory.ini playbooks/rollback.yml
```

## Это решение обеспечивает:

Полную автоматизацию процесса обновления

Минимальное время простоя

Встроенные механизмы проверки состояния

Четкую документацию

Возможность интеграции в CI/CD
