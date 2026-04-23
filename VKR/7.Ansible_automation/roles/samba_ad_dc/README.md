# Роль Ansible: samba_ad_dc - Контроллер домена Active Directory

Данный репозиторий содержит Для Демонстрации автоматизированную конфигурацию для развертывания и управления доменной инфраструктурой на базе Samba Active Directory в среде **ALT Linux** (семейство `apt-rpm`). Роль обеспечивает полную автоматизацию настройки первичного и вторичного контроллеров домена, включая провижинирование, репликацию, настройку DNS, Kerberos, обратных зон и автоматическое разрешение конфликтов системных служб.

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

---

## Структура проекта
```
.
├── ansible.cfg                 # Локальная конфигурация Ansible
├── va_pa                       # Файл с паролем от Vault (НЕ коммитить!)
├── main.yaml                   # Главный плейбук-оркестратор
├── samba_ad_dc.yaml            # Плейбук вызова роли контроллера домена
├── inventory/
│   ├── inventory.yaml          # Инвентаризация хостов (YAML)
│   └── group_vars/
│       └── all/
│           ├── all.yml         # Глобальные переменные
│           └── vault           # Зашифрованные секреты (пароли, ключи)
└── roles/
    └── samba_ad_dc/            # Каталог роли контроллера домена
        ├── tasks/
        │   ├── main.yml        # Точка входа и распределение задач
        │   ├── base.yml        # Базовая подготовка всех DC
        │   ├── primary_dc.yml  # Провижинирование первичного DC
        │   └── second_dc.yml   # Присоединение и настройка вторичного DC
        ├── templates/
        │   ├── resolv.conf_dc_main.j2
        │   ├── resolv.conf_second_dc_before.j2
        │   ├── resolv.conf_dc_second.j2
        │   └── krb5.conf.dc_second.j2
        ├── handlers/
        │   └── main.yml        # Обработчики перезапуска сети и интерфейсов
        ├── vars/
        │   └── main.yml        # Константы и списки пакетов/служб
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
- **`inventory/inventory.yaml`** описывает группу хостов `domain_controllers` (altsrv2, altsrv3), которая является целевой для этой роли.
- **`inventory/group_vars/all/all.yml`** содержит параметры, используемые ролью:
  - `ad_workgroup`, `ad_realm`, `ad_domain`: параметры домена и рабочей группы
  - `ad_admin_user`: учетная запись администратора домена
  - `dns_forwarder`: внешний DNS-резолвер
  - `ad_backend`: бэкенд DNS (`SAMBA_INTERNAL`)
  - `dns_refresh`: интервал очистки зон (720 часов)
  - `ptr_zone`, `ptr_ip_main_dc`, `ptr_ip_second_dc`: параметры обратной зоны
  - `ldap_search`: база поиска LDAP
  - `sysvol_replication`: триггер репликации и развертывания вторичного DC
  - `samba_ad_dc`: триггер включения роли (`true`/`false`)

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

Роль `samba_ad_dc` выполняет развертывание по строгому сценарию, разделенному на три файла задач:

1. **Базовая подготовка (`base.yml`)**
   - Останавливает и маскирует конфликтующие службы (`smb`, `nmb`, `krb5kdc`, `slapd`, `bind`, `dnsmasq`)
   - Обновляет кеш пакетов и устанавливает `task-samba-dc`, `alterator-net-domain`, `alterator-datetime`
   - Определяет основной сетевой интерфейс
   - Настраивает резолвер для вторичного DC до ввода в домен и перезагружает сеть
   - Очищает стандартные конфигурационные файлы Samba и создает директорию `/var/lib/samba/sysvol`

2. **Развертывание первичного DC (`primary_dc.yml`)**
   - Выполняет `samba-tool domain provision` с параметрами из инвентаря и Vault
   - Запускает службу `samba`, ожидает открытия порта 53
   - Настраивает aging и refresh-интервал для зоны домена
   - Создает обратную PTR-зону и добавляет PTR-записи для обоих контроллеров
   - Добавляет A-запись для вторичного DC
   - Применяет финальный `resolv.conf` и копирует сгенерированный `krb5.conf` в `/etc/`

3. **Присоединение вторичного DC (`second_dc.yml`)**
   - Применяет шаблон `krb5.conf` для Kerberos-аутентификации
   - Получает билет `kinit Administrator`
   - Выполняет `samba-tool domain join DC` с указанными опциями
   - Запускает Samba, проверяет доступность DNS
   - Применяет финальный резолвер для вторичного узла
   - Инициирует репликацию каталога `dc=den,dc=skv` с первичного на вторичный контроллер

Все сетевые изменения применяются через обработчики (`handlers`), которые асинхронно перезапускают интерфейсы и сетевые службы, игнорируя временную потерю соединения.

---

## Запуск плейбуков

```bash
# Проверка синтаксиса и подключения
ansible-inventory -i inventory/inventory.yaml --list --yaml
ansible domain_controllers -m ping -i inventory/inventory.yaml --vault-password-file ./va_pa

# Запуск только роли контроллера домена
ansible-playbook -i inventory/inventory.yaml samba_ad_dc.yaml \
  --vault-password-file ./va_pa

# Запуск через главный плейбук (с учетом триггера samba_ad_dc)
ansible-playbook -i inventory/inventory.yaml main.yaml \
  --vault-password-file ./va_pa
```

> Переменные `ad_backend`, `dns_refresh`, `ptr_zone`, `sysvol_replication` и `samba_ad_dc` можно переопределить через `--extra-vars` или в `group_vars`.

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
5. Для автоматизации развертывания в CI/CD используйте переменные окружения `ANSIBLE_VAULT_PASSWORD_FILE` вместо передачи параметра в командной строке.
6. После применения роли проверьте статус репликации командой `samba-tool drs showrepl` и убедитесь в корректной работе DNS через `nslookup` или `dig`.