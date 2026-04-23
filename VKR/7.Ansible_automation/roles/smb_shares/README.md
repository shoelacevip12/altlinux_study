# Роль Ansible: smb_shares - SMB файловый сервер с интеграцией в домен

Данный репозиторий содержит Для Демонстрации автоматизированную конфигурацию для развертывания и управления файловым сервером на базе Samba с интеграцией в домен Active Directory на базе **ALT Linux** (семейство `apt-rpm`). Роль обеспечивает автоматическое создание доменных пользователей и групп, настройку сетевых ресурсов с разграничением прав доступа, присоединение сервера к домену и конфигурацию службы SMB для работы в корпоративной среде.

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
├── smb_shares.yaml             # Плейбук вызова роли SMB-сервера
├── inventory/
│   ├── inventory.yaml          # Инвентаризация хостов (YAML)
│   └── group_vars/
│       └── all/
│           ├── all.yml         # Глобальные переменные
│           └── vault           # Зашифрованные секреты (пароли, ключи)
└── roles/
    └── smb_shares/             # Каталог роли SMB-сервера
        ├── tasks/
        │   ├── main.yml        # Точка входа и распределение задач
        │   ├── ad_prerare.yml  # Подготовка AD: DNS, пользователи, группы
        │   └── smb_install.yml # Установка и настройка SMB-сервера
        ├── templates/
        │   ├── smb.conf.j2           # Основной конфиг Samba
        │   └── usershares.conf.j2    # Конфигурация сетевых ресурсов
        ├── handlers/
        │   └── main.yml        # Обработчики перезапуска служб
        ├── vars/
        │   └── main.yml        # Константы и списки пакетов
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
- **`inventory/inventory.yaml`** описывает группы хостов `file_servers` и `domain_controllers`, участвующие в настройке файловых ресурсов.
- **`inventory/group_vars/all/all.yml`** содержит параметры, используемые ролью:
  - `ad_workgroup`, `ad_realm`, `ad_domain`: параметры домена
  - `ad_admin_user`, `ad_admin_password`: учетные данные администратора домена
  - `primary_dc`, `secondary_dc`: контроллеры домена для DNS-записей
  - `ptr_zone`: обратная зона для PTR-записей
  - `spec_smb_gr1`: имя специальной доменной группы для разграничения доступа
  - `samba_users`: словарь доменных пользователей с параметрами (имя, пароль, отображаемое имя, email)
  - `smb_shares_config`: конфигурация сетевых ресурсов с параметрами доступа, масками прав и комментариями
  - `smb_shares`: триггер включения роли (`true`/`false`)

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

Роль `smb_shares` выполняет настройку по следующему сценарию:

1. **Подготовка доменной инфраструктуры** (выполняется на первичном контроллере домена)
   - Добавляет A-записи для файловых серверов в зоне домена
   - Добавляет PTR-записи для обратной зоны
   - Создает специальную доменную группу `Специальная_группа`
   - Создает доменных пользователей с указанными параметрами (имя, пароль, отображаемое имя, email)
   - Устанавливает бессрочный срок действия учетных записей
   - Добавляет пользователей в специальную группу

2. **Установка и настройка SMB-сервера** (выполняется на хостах группы `file_servers`)
   - Обновляет кеш пакетов и устанавливает `samba`, `avahi-daemon`, `libnss-role`
   - Включает поддержку ролей через `libnss-role enabled`
   - Проверяет статус присоединения к домену через `net ads testjoin`
   - При необходимости выполняет присоединение к домену через `system-auth write ad`
   - Разворачивает конфигурационный файл `smb.conf` с параметрами домена, Kerberos и idmap
   - Включает и запускает службы `smb` и `avahi-daemon`
   - Создает каталоги для сетевых ресурсов с указанными владельцами и группами
   - Настраивает права доступа для каждого ресурса согласно конфигурации:
     - `VG`: доступ для специальной группы и администраторов
     - `trash`: общий доступ для всех пользователей домена с битом sticky
     - `IT`: закрытый ресурс только для администраторов
     - `Work`: рабочие каталоги для пользователей домена
   - Разворачивает дополнительный конфиг `usershares.conf` с определениями сетевых шар

3. **Применение изменений**
   - Обработчик `перезапуск smb` асинхронно перезапускает службы `smb` и `avahi-daemon`

---

## Запуск плейбуков

```bash
# Проверка синтаксиса и подключения
ansible-inventory -i inventory/inventory.yaml --list --yaml
ansible file_servers -m ping -i inventory/inventory.yaml --vault-password-file ./va_pa

# Запуск только роли SMB-сервера
ansible-playbook -i inventory/inventory.yaml smb_shares.yaml \
  --vault-password-file ./va_pa

# Запуск через главный плейбук (с учетом триггера smb_shares)
ansible-playbook -i inventory/inventory.yaml main.yaml \
  --vault-password-file ./va_pa
```

> Переменные `smb_shares`, `spec_smb_gr1`, `samba_users`, `smb_shares_config` можно переопределить через `--extra-vars` или в `group_vars`.

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
5. Пароли доменных пользователей, указанные в `smb_shares_config`, должны соответствовать политике сложности паролей домена.
6. Для автоматизации развертывания в CI/CD используйте переменные окружения `ANSIBLE_VAULT_PASSWORD_FILE` вместо передачи параметра в командной строке.
7. После применения роли проверьте доступ к ресурсам командой `smbclient -L //hostname -U username` и убедитесь в корректной работе аутентификации через домен.
8. Регулярно проверяйте логи Samba `/var/log/samba/` на предмет ошибок аутентификации или доступа.
9. При изменении прав доступа к ресурсам обновляйте конфигурацию через Ansible, а не вручную, чтобы избежать рассинхронизации состояния.