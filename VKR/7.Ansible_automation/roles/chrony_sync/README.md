# Роль Ansible: chrony_sync - Синхронизация времени

Данный репозиторий содержит Для Демонстрации автоматизированную конфигурацию для развертывания и управления службой синхронизации времени Chrony в гибридной инфраструктуре на базе **ALT Linux** (семейство `apt-rpm`). Роль обеспечивает корректную настройку временных источников для контроллеров домена и рядовых узлов, учитывая требования репликации и локальной подсети.

---

## Содержание
- [Требования](#требования)
- [Структура проекта](#структура-проекта)
- [Подготовка управляющего узла](#подготовка-управляющего-узла)
- [Подготовка управляемых узлов](#подготовка-управляемых-узлов)
- [Конфигурация](#конфигурация)
  - [ansible.cfg](#ansiblecfg)
  - [Инвентаризация и переменные](#инвентаризация-и-переменные)
  - [Ansible Vault](#ansible-vault)
- [Логика работы роли](#логика-работы-роли)
- [Запуск плейбуков](#запуск-плейбуков)
- [Рекомендации по безопасности](#рекомендации-по-безопасности)

---

## Требования
| Компонент | Версия / Примечание |
|-----------|---------------------|
| **ОС** | ALT Linux (совместимость с `apt-rpm`, `update-kernel`) |
| **Ansible** | `>= 2.14` |
| **Python** | `3.x` на управляемых узлах |
| **Доступ** | SSH-ключ, пользователь `sysadmin` как `ansible_user` |
| **Утилиты** | `sshpass`, `pwgen` или `pwqgen`, `nano` |

---

## Структура проекта
```
.
├── ansible.cfg                 # Локальная конфигурация Ansible
├── va_pa                       # Файл с паролем от Vault (НЕ коммитить!)
├── main.yaml                   # Главный плейбук-оркестратор
├── chrony_sync.yaml            # Плейбук вызова роли синхронизации времени
├── inventory/
│   ├── inventory.yaml          # Инвентаризация хостов (YAML)
│   └── group_vars/
│       └── all/
│           ├── all.yml         # Глобальные переменные
│           └── vault           # Зашифрованные секреты
└── roles/
    └── chrony_sync/            # Каталог роли синхронизации времени
        ├── tasks/
        │   └── main.yml        # Основной файл задач
        ├── templates/
        │   ├── chrony.conf.dc_main.j2    # Конфиг для первичного DC
        │   ├── chrony.conf.dc_second.j2  # Конфиг для вторичного DC
        │   └── chrony.conf.members.j2    # Конфиг для рядовых узлов
        ├── handlers/
        │   └── main.yml        # Обработчики перезапуска службы
        └── defaults/
            └── main.yml        # Переменные по умолчанию
```

---

## Подготовка управляющего узла

1. **Подключение к управляющему хосту**
   ```bash
   ssh -t \
   -o StrictHostKeyChecking=accept-new \
   sysadmin@172.16.100.2 "su -"
   ```

2. **Коррекция прав на SSH-ключи**
   ```bash
   chown -v sysadmin:sysadmin /home/sysadmin/.ssh/id_skv_VKR_vp*
   chmod -v 600 /home/sysadmin/.ssh/id_skv_VKR_vpn
   chmod -v 640 /home/sysadmin/.ssh/id_skv_VKR_vpn.pub
   ```

3. **Обновление системы и установка зависимостей**
   ```bash
   apt-get update && update-kernel -y && apt-get dist-upgrade -y
   apt-get install ansible sshpass -y && apt-get autoremove -y
   ```

4. **Установка коллекции и настройка среды**
   ```bash
   su - sysadmin
   ansible-galaxy collection install community.general
   echo -e "\nexport ANSIBLE_CALLBACK_RESULT_FORMAT=yaml" | tee -a ~/.bashrc && . ~/.bashrc
   ```

5. **Перезагрузка узла**
   ```bash
   su - && systemctl reboot
   ```

---

## Подготовка управляемых узлов

1. **Проброс SSH-ключей** (выполняется с управляющего узла)
   ```bash
   > ~/.ssh/known_hosts
   for ip in {2,11,12,13,14}; do \
     ssh-copy-id -o StrictHostKeyChecking=accept-new \
     -i /home/sysadmin/.ssh/id_skv_VKR_vpn.pub \
     sysadmin@192.168.100.$ip; done
   ```

2. **Установка Python-зависимостей для Ansible**
   ```bash
   for ip in {2,11,12,13,14}; do \
   ssh -t -i /home/sysadmin/.ssh/id_skv_VKR_vpn \
   -o StrictHostKeyChecking=accept-new \
   sysadmin@192.168.100."$ip" \
   "su -c 'apt-get update && apt-get install -y python3 python3-module-yaml python3-module-jinja2 python3-module-jsonobject && systemctl reboot'" ; done
   ```

---

## Конфигурация

### `ansible.cfg`
Локальная конфигурация отключает проверку хост-ключей (для удобства в тестовой среде), задает путь к инвентарю и ролям, а также переключает механизм повышения привилегий на `su`:
```ini
[defaults]
home=./
inventory=./inventory
roles_path=./roles
vault_password_file=./va_pa
host_key_checking=False
interpreter_python=auto_silent
deprecation_warnings=False
retry_files_enabled=False
callback_enabled=profile_tasks

[privilege_escalation]
become=true
become_method=su

[connection]
ssh_agent=auto

[paramiko_connection]
host_key_checking=False

[ssh_connection]
host_key_checking=False
```

### Инвентаризация и переменные
- **`inventory/inventory.yaml`** описывает группы хостов: `domain_controllers`, `file_servers`, `proxy_servers`.
- **`inventory/group_vars/all/all.yml`** содержит параметры, используемые ролью:
  - `ad_workgroup`: доменное имя (используется в шаблонах DNS имен)
  - `exter_ntp`: внешний NTP-сервер (по умолчанию `ntp3.vniiftri.ru`)
  - `allow_clients`: подсеть, которой разрешено обращаться к локальному NTP (`192.168.100.0/24`)
  - `chrony_sync`: триггер включения роли (`true`/`false`)
  - `sysvol_replication`: флаг репликации, влияющий на конфигурацию вторичного DC

### Ansible Vault
Секреты хранятся в зашифрованном файле `inventory/group_vars/all/vault`. Пароль для доступа генерируется автоматически и сохраняется в `./va_pa`.

**Создание и редактирование:**
```bash
# Генерация пароля и создание vault
tee ./va_pa <<< $(pwgen -1) && chmod -x ./va_pa
или
tee ./va_pa <<< $(pwqgen) && chmod -x ./va_pa

EDITOR=nano ansible-vault create --vault-password-file ./va_pa ./inventory/group_vars/all/vault

# Последующее редактирование
EDITOR=nano ansible-vault edit ./inventory/group_vars/all/vault --vault-password-file ./va_pa
```
> В `vault` хранятся: `ansible_user`, `ansible_become_password`, `ad_admin_password`, `vault_omapi_secret`.

---

## Логика работы роли

Роль `chrony_sync` автоматически определяет роль хоста в инфраструктуре и применяет соответствующий шаблон конфигурации `/etc/chrony.conf`:

1. **Первичный контроллер домена** (`chrony.conf.dc_main.j2`)
   - Синхронизируется с внешним NTP-сервером (`exter_ntp`)
   - Синхронизируется со вторичным DC
   - Разрешает клиентам из `allow_clients` запрашивать время
   - Работает в режиме `local stratum 10` при потере связи

2. **Вторичный контроллер домена** (`chrony.conf.dc_second.j2`)
   - Синхронизируется с первичным DC и внешним NTP
   - Применяется только при `sysvol_replication: true`

3. **Рядовые узлы домена** (`chrony.conf.members.j2`)
   - Синхронизируются только с контроллерами домена
   - Не выступают источником времени для других узлов

После применения конфигурации вызывается обработчик `Restart chronyd`, который перезапускает и включает службу `chronyd` через `systemd`.

---

## Запуск плейбуков

```bash
# Проверка синтаксиса и подключения
ansible-inventory -i inventory/inventory.yaml --list --yaml
ansible all -m ping -i inventory/inventory.yaml --vault-password-file ./va_pa

# Запуск только роли синхронизации времени
ansible-playbook -i inventory/inventory.yaml chrony_sync.yaml \
  --vault-password-file ./va_pa

# Запуск через главный плейбук (с учетом триггера chrony_sync)
ansible-playbook -i inventory/inventory.yaml main.yaml \
  --vault-password-file ./va_pa
```

> Переменные `exter_ntp`, `allow_clients`, `chrony_sync` можно переопределить через `--extra-vars` или в `group_vars`.

---

## Рекомендации по безопасности

1. Файлы **`va_pa` и `vault`** не должны попадать в открытые источники. Добавьте их в `.gitignore`:
   ```gitignore
   va_pa
   inventory/group_vars/all/vault
   *.retry
   ```
2. **`host_key_checking = False`** удобно для тестов, но в production рекомендуется использовать известные хост-ключи или настроить `known_hosts`.
3. **SSH-ключи**: Убедитесь, что приватный ключ имеет права `600`, а публичный `644`/`640` на всех узлах.
4. Для автоматизации развертывания в CI/CD используйте переменные окружения `ANSIBLE_VAULT_PASSWORD_FILE` вместо передачи параметра в командной строке.
5. Регулярно проверяйте статус синхронизации командой `chronyc tracking` и `chronyc sources` на управляемых узлах после применения роли.