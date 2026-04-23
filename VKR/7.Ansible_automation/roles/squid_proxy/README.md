# Роль Ansible: squid_proxy - Прокси-сервер SQUID с Kerberos-аутентификацией

Данный репозиторий содержит Для Демонстрации автоматизированную конфигурацию для развертывания и управления прокси-сервером SQUID с интеграцией в домен Active Directory и аутентификацией пользователей через Kerberos на базе **ALT Linux** (семейство `apt-rpm`). Роль обеспечивает автоматическое создание доменных пользователей и групп для доступа в интернет, получение сервисных принципалов, настройку кэширования и конфигурацию правил контроля доступа через внешнюю проверку групп LDAP.

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
| **Зависимости** | Предварительно развернутый Samba AD DC с работающим Kerberos и синхронизацией времени |

---

## Структура проекта
```
.
├── ansible.cfg                 # Локальная конфигурация Ansible
├── va_pa                       # Файл с паролем от Vault (НЕ коммитить!)
├── main.yaml                   # Главный плейбук-оркестратор
├── squid_proxy.yaml            # Плейбук вызова роли прокси-сервера
├── inventory/
│   ├── inventory.yaml          # Инвентаризация хостов (YAML)
│   └── group_vars/
│       └── all/
│           ├── all.yml         # Глобальные переменные
│           └── vault           # Зашифрованные секреты (пароли, ключи)
└── roles/
    └── squid_proxy/            # Каталог роли прокси-сервера
        ├── tasks/
        │   ├── main.yml        # Точка входа и распределение задач
        │   ├── groups_proxy_add.yml  # Создание AD-групп и пользователей
        │   └── install_squid.yml     # Установка и настройка SQUID
        ├── templates/
        │   └── squid.conf.j2   # Шаблон конфигурации SQUID с Kerberos
        ├── handlers/
        │   └── main.yml        # Обработчики перезапуска службы
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
- **`inventory/inventory.yaml`** описывает группы хостов `proxy_servers` и `domain_controllers`, участвующие в настройке прокси-инфраструктуры.
- **`inventory/group_vars/all/all.yml`** содержит параметры, используемые ролью:
  - `ad_workgroup`, `ad_realm`, `ad_domain`: параметры домена и области Kerberos
  - `ad_admin_user`, `ad_admin_password`: учетные данные администратора домена
  - `proxy_group`: имя доменной группы для контроля доступа (`proxy_acc`)
  - `samba_users`: словарь доменных пользователей с параметрами (имя, пароль, отображаемое имя, email)
  - `negotiate_param`: параметры хелпера аутентификации Kerberos
  - `cache_mem`, `cache_dir`, `max_obj_size`, `max_obj_size_mem`: параметры кэширования SQUID
  - `squid_proxy`: триггер включения роли (`true`/`false`)

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

## Запуск плейбуков

```bash
# Проверка синтаксиса и подключения
ansible-inventory -i inventory/inventory.yaml --list --yaml
ansible proxy_servers -m ping -i inventory/inventory.yaml --vault-password-file ./va_pa

# Запуск только роли прокси-сервера
ansible-playbook -i inventory/inventory.yaml squid_proxy.yaml \
  --vault-password-file ./va_pa

# Запуск через главный плейбук (с учетом триггера squid_proxy)
ansible-playbook -i inventory/inventory.yaml main.yaml \
  --vault-password-file ./va_pa
```

> Переменные `squid_proxy`, `proxy_group`, `samba_users`, `cache_mem`, `cache_dir` можно переопределить через `--extra-vars` или в `group_vars`.

---

## Рекомендации по безопасности

1. Файлы **`va_pa` и `vault`** не должны попадать в открытые источники. Добавьте их в `.gitignore`:
   ```gitignore
   va_pa
   inventory/group_vars/all/vault
   *.retry
   ```
2. Все команды `samba-tool` и `net ads` с передачей паролей защищены директивой `no_log: true`, однако убедитесь, что логи системы управления не кешируют вывод в открытом виде.
3. **`host_key_checking = False`** удобно для тестов, но в production рекомендуется использовать известные хост-ключи или настроить `known_hosts`.
4. **SSH-ключи**: Убедитесь, что приватный ключ имеет права `600`, а публичный `644`/`640` на всех узлах.
5. Пароли доменных пользователей, указанные в `samba_users`, должны соответствовать политике сложности паролей домена.
6. Для работы Kerberos-аутентификации критически важна синхронизация времени между прокси-сервером и контроллерами домена (расхождение не более 5 минут).
7. Для автоматизации развертывания в CI/CD используйте переменные окружения `ANSIBLE_VAULT_PASSWORD_FILE` вместо передачи параметра в командной строке.
8. После применения роли проверьте работу аутентификации через журнал `/var/log/squid/cache.log` и убедитесь, что доступ разрешен только пользователям, входящим в группу `proxy_acc`.
9. При изменении правил доступа или параметров кэша обновляйте конфигурацию через Ansible, а не вручную, чтобы избежать рассинхронизации состояния и некорректной работы хелперов.