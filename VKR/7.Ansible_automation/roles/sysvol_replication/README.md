# Роль Ansible: sysvol_replication - Репликация SysVol между контроллерами домена

Данный репозиторий содержит Для Демонстрации автоматизированную конфигурацию для настройки двунаправленной репликации каталога SysVol между контроллерами домена Samba Active Directory на базе **ALT Linux** (семейство `apt-rpm`). Роль использует связку Unison и rsync поверх SSH для синхронизации групповых политик, скриптов входа и других критических данных домена с автоматизацией через systemd timer.

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
| **Зависимости** | Предварительно развернутый Samba AD DC с двумя контроллерами |

---

## Структура проекта
```
.
├── ansible.cfg                 # Локальная конфигурация Ansible
├── va_pa                       # Файл с паролем от Vault (НЕ коммитить!)
├── main.yaml                   # Главный плейбук-оркестратор
├── sysvol_replication.yaml     # Плейбук вызова роли репликации SysVol
├── inventory/
│   ├── inventory.yaml          # Инвентаризация хостов (YAML)
│   └── group_vars/
│       └── all/
│           ├── all.yml         # Глобальные переменные
│           └── vault           # Зашифрованные секреты (пароли, ключи)
└── roles/
    └── sysvol_replication/     # Каталог роли репликации SysVol
        ├── tasks/
        │   └── main.yml        # Основной файл задач
        ├── templates/
        │   ├── sync_dc2.prf.j2              # Конфигурация профиля Unison
        │   ├── sysvol-sync.service.j2       # Unit-файл службы systemd
        │   └── sysvol-sync.timer.j2         # Unit-файл таймера systemd
        ├── handlers/
        │   └── main.yml         # Обработчики активации таймера
        ├── vars/
        │   └── main.yml         # Константы и списки пакетов
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
- **`inventory/inventory.yaml`** описывает группу хостов `domain_controllers`, между которыми настраивается репликация.
- **`inventory/group_vars/all/all.yml`** содержит параметры, используемые ролью:
  - `ad_workgroup`, `ad_realm`: параметры домена для построения полных имен хостов
  - `primary_dc`, `secondary_dc`: имена хостов контроллеров домена
  - `ssh_sysvol_path`: путь к приватному SSH-ключу для репликации (`/root/.ssh/id_sysvol_ed25519`)
  - `synchron_path`: путь к каталогу SysVol для синхронизации (`/var/lib/samba/sysvol`)
  - `sysvol_replication`: триггер включения роли (`true`/`false`)

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

Роль `sysvol_replication` выполняет настройку репликации по следующему сценарию:

1. **Установка зависимостей**
   - Обновляет кеш пакетов и устанавливает `unison`, `rsync`, `openssh-clients`

2. **Настройка SSH-аутентификации для репликации**
   - На первичном контроллере генерирует ключевую пару Ed25519 в `/root/.ssh/id_sysvol_ed25519`
   - Устанавливает права `0600` на приватный ключ и `0640` на публичный
   - На вторичном контроллере добавляет публичный ключ первичного в `authorized_keys` пользователя `root`

3. **Развертывание конфигурации Unison**
   - Создает директорию `/root/.unison`
   - Применяет шаблон `sync_dc2.prf.j2` с параметрами:
     - Двунаправленная синхронизация каталога `sysvol`
     - Использование rsync как транспорта с опциями `-XAavz`
     - Логирование в `/var/log/sysvol-sync.log`
     - Отключение подтверждения крупных удалений (`confirmbigdeletes=false`)

4. **Первоначальная синхронизация**
   - Выполняет ручную синхронизацию через `rsync` для начального переноса данных
   - Запускает `unison` через `ssh-agent` для финальной проверки консистентности

5. **Автоматизация через systemd**
   - Разворачивает unit-файлы `sysvol-sync.service` и `sysvol-sync.timer`
   - Служба запускает `unison sync_dc2` в фоновом режиме с использованием ssh-agent
   - Таймер активирует синхронизацию каждые 5 минут после первой загрузки системы
   - Обработчик включает и активирует таймер на первичном контроллере

---

## Запуск плейбуков

```bash
# Проверка синтаксиса и подключения
ansible-inventory -i inventory/inventory.yaml --list --yaml
ansible domain_controllers -m ping -i inventory/inventory.yaml --vault-password-file ./va_pa

# Запуск только роли репликации SysVol
ansible-playbook -i inventory/inventory.yaml sysvol_replication.yaml \
  --vault-password-file ./va_pa

# Запуск через главный плейбук (с учетом триггера sysvol_replication)
ansible-playbook -i inventory/inventory.yaml main.yaml \
  --vault-password-file ./va_pa
```

> Переменные `sysvol_replication`, `ssh_sysvol_path`, `synchron_path` можно переопределить через `--extra-vars` или в `group_vars`.

---

## Рекомендации по безопасности

1. Файлы **`va_pa` и `vault`** не должны попадать в открытые источники. Добавьте их в `.gitignore`:
   ```gitignore
   va_pa
   inventory/group_vars/all/vault
   *.retry
   ```
2. SSH-ключ для репликации `/root/.ssh/id_sysvol_ed25519` должен иметь права `0600` и не использоваться для других целей.
3. **`host_key_checking = False`** удобно для тестов, но в production рекомендуется использовать известные хост-ключи или настроить отдельный `known_hosts` для репликации.
4. Для автоматизации развертывания в CI/CD используйте переменные окружения `ANSIBLE_VAULT_PASSWORD_FILE` вместо передачи параметра в командной строке.
5. Регулярно проверяйте лог синхронизации `/var/log/sysvol-sync.log` на наличие ошибок или конфликтов.
6. Убедитесь, что таймер активен командой `systemctl list-timers | grep sysvol` и служба выполняется без ошибок через `systemctl status sysvol-sync.service`.
7. При изменении групповых политик вручную на одном из контроллеров дождитесь завершения синхронизации перед внесением изменений на другом узле во избежание конфликтов.