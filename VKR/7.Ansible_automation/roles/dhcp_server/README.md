# Роль Ansible: dhcp_server - DHCP с failover и динамическим обновлением DNS

Данный репозиторий содержит Для Демонстрации автоматизированную конфигурацию для развертывания и управления DHCP-сервером с поддержкой отказоустойчивой конфигурации (failover) и безопасного динамического обновления записей DNS в домене Samba Active Directory на базе **ALT Linux** (семейство `apt-rpm`). Роль обеспечивает автоматическую регистрацию и удаление записей типа A и PTR при выдаче, освобождении или истечении срока аренды IP-адресов.

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
| **Утилиты** | `sshpass`, `pwgen`, `nano`, `pwqgen` |
| **Зависимости** | Предварительно развернутый Samba AD DC |

---

## Структура проекта
```
.
├── ansible.cfg                 # Локальная конфигурация Ansible
├── va_pa                       # Файл с паролем от Vault (НЕ коммитить!)
├── main.yaml                   # Главный плейбук-оркестратор
├── dhcp_server.yaml            # Плейбук вызова роли DHCP-сервера
├── inventory/
│   ├── inventory.yaml          # Инвентаризация хостов (YAML)
│   └── group_vars/
│       └── all/
│           ├── all.yml         # Глобальные переменные
│           └── vault           # Зашифрованные секреты (пароли, ключи)
└── roles/
    └── dhcp_server/            # Каталог роли DHCP-сервера
        ├── tasks/
        │   └── main.yml        # Основной файл задач
        ├── templates/
        │   ├── dhcpd.conf.j2                    # Конфиг для одиночного сервера
        │   ├── dhcpd_failover_primary.conf.j2   # Конфиг для первичного узла failover
        │   └── dhcpd_failover_second.conf.j2    # Конфиг для вторичного узла failover
        ├── files/
        │   └── dhcp-dyndns.sh   # Скрипт безопасного обновления DNS
        ├── handlers/
        │   └── main.yml         # Обработчики перезапуска службы
        ├── vars/
        │   └── main.yml         # Константы и параметры по умолчанию
        └── defaults/
            └── main.yml         # Переменные по умолчанию
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
- **`inventory/inventory.yaml`** описывает группу хостов `domain_controllers`, на которых развертывается DHCP-сервер.
- **`inventory/group_vars/all/all.yml`** содержит параметры, используемые ролью:
  - `ad_workgroup`, `ad_realm`, `ad_domain`: параметры домена
  - `primary_dc`, `secondary_dc`, `primary_dc_ip`, `secondary_dc_ip`: контроллеры домена
  - `network_subnet`, `network_netmask`, `network_gateway`, `broadcast`: параметры сети
  - `dhcp_range`: диапазон выдаваемых адресов
  - `lease_time`, `max_lease_time`: время аренды
  - `sysvol_replication`: триггер включения режима failover
  - `dhcp_server`: триггер включения роли (`true`/`false`)
  - `vault_omapi_secret`: секрет для аутентификации OMAPI в режиме failover

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

Роль `dhcp_server` выполняет настройку по следующему сценарию:

1. **Базовая установка**
   - Обновляет кеш пакетов и устанавливает `dhcp-server`
   - Создает пользователя `dhcpduser` в AD с описанием и случайным паролем
   - Добавляет пользователя в группу `DnsAdmins` для прав на обновление DNS
   - Устанавливает бессрочный срок действия учетной записи

2. **Настройка аутентификации для DDNS**
   - Экспортирует keytab-файл для пользователя `dhcpduser` через `samba-tool domain exportkeytab`
   - Устанавлиает права `0400` и владельца `dhcpd:dhcp` на файл keytab

3. **Развертывание скрипта обновления DNS**
   - Копирует `dhcp-dyndns.sh` в `/usr/local/bin/` с правами выполнения
   - Скрипт обеспечивает:
     - Проверку и обновление Kerberos-билета
     - Добавление/удаление записей A и PTR через `samba-tool dns`
     - Поддержку нескольких обратных зон

4. **Генерация конфигурации dhcpd.conf**
   - При `sysvol_replication: false` применяется шаблон одиночного сервера
   - При `sysvol_replication: true`:
     - На первичном узле применяется `dhcpd_failover_primary.conf.j2`
     - На вторичном узле применяется `dhcpd_failover_second.conf.j2`
   - Конфигурация включает:
     - Настройку OMAPI с HMAC-MD5 аутентификацией
     - Параметры failover (primary/secondary, порты, таймауты)
     - Обработчики событий `on commit`, `on release`, `on expiry` для вызова скрипта DDNS

5. **Завершение настройки**
   - Отключает chroot для DHCP-сервера через `control dhcpd-chroot disabled`
   - Перезапускает службу `dhcpd` через обработчик

---

## Запуск плейбуков

```bash
# Проверка синтаксиса и подключения
ansible-inventory -i inventory/inventory.yaml --list --yaml
ansible domain_controllers -m ping -i inventory/inventory.yaml --vault-password-file ./va_pa

# Запуск только роли DHCP-сервера
ansible-playbook -i inventory/inventory.yaml dhcp_server.yaml \
  --vault-password-file ./va_pa

# Запуск через главный плейбук (с учетом триггера dhcp_server)
ansible-playbook -i inventory/inventory.yaml main.yaml \
  --vault-password-file ./va_pa
```

> Переменные `dhcp_range`, `lease_time`, `sysvol_replication`, `dhcp_server` можно переопределить через `--extra-vars` или в `group_vars`.

---

## Рекомендации по безопасности

1. Файлы **`va_pa` и `vault`** не должны попадать в открытые источники. Добавьте их в `.gitignore`:
   ```gitignore
   va_pa
   inventory/group_vars/all/vault
   *.retry
   ```
2. Все команды `samba-tool` с передачей паролей защищены директивой `no_log: true`, однако убедитесь, что логи системы управления не кешируют вывод в открытом виде.
3. **`host_key_checking = False`** удобно для тестов, но в production рекомендуется использовать известные хост-ключи или настроить `known_hosts`.
4. **SSH-ключи**: Убедитесь, что приватный ключ имеет права `600`, а публичный `644`/`640` на всех узлах.
5. Файл keytab `/etc/dhcp/dhcpduser.keytab` должен иметь права `0400` и принадлежать пользователю `dhcpd`.
6. Для автоматизации развертывания в CI/CD используйте переменные окружения `ANSIBLE_VAULT_PASSWORD_FILE` вместо передачи параметра в командной строке.
7. После применения роли проверьте работу DHCP командой `systemctl status dhcpd` и убедитесь в корректном обновлении DNS через `samba-tool dns query` или `nslookup`.
8. В режиме failover убедитесь, что порты 847 и 647 открыты между контроллерами домена для синхронизации состояния аренды.