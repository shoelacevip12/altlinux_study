# Впускная квалификационная работа
# `Проектирование и автоматизация внедрения гибридной сетевой инфраструктуры на базе Ansible в составе домена AD, прокси-сервера SQUID и Динамического DNS`

![](0.vpn/img/1.png)

# Памятка входа
```bash
export ANSIBLE_CONFIG=./ansible.cfg

# Команда вызова редактирования файла с паролями
EDITOR=nano \
ansible-vault edit \
./inventory/group_vars/all/vault.yml \
--vault-password-file ./va_pa
```
```bash
# Включаем агента в текущей оснастке
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn
```
```bash
# вход на bastion(altwks1) хост по ключу по ssh через yandex cloud vm
> ~/.ssh/known_hosts \
&& ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J skv@158.160.201.144 \
-o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"su -"
```

# Ход выполнения Автоматизации
## Предварительные действия перед выполнением (Доступ до закрытого контура через Openvpn)
### Развертывание сервера Сертификации на сервере Openvpn
#### Установка пакетов на сервере Openvpn
```bash
# Вход в каталога с подготовленным terraform для развертывания openvpn-сервер узла
cd  VKR/0.vpn/tf

# Вывод рабочего облака
yc config get cloud-id
```
```log
b1gkumrn87pei2831blp
```
```bash
# вывод рабочего каталога YC
yc config get folder-id
```
```log
b1g7qviodfc9v4k81sr5
```
```bash
# Проверка готовых конфигов проекта и вывод плана развертывания
terraform validate \
&& terraform fmt \
&& terraform init --upgrade \
&& terraform plan -out=tfplan
```
```bash
# Формирование Сервера
terraform apply "tfplan"
```
```bash
# вывод имеющихся виртуальных машин
yc compute instance list
```
|          ID          | NAME |    ZONE ID    | STATUS  |   EXTERNAL IP   | INTERNAL IP  |
|----------------------|------|---------------|---------|-----------------|--------------|
| fv4clqtg1jq6rde85jcc | vkr  | ru-central1-d | RUNNING | 158.160.201.144 | 10.10.10.254 |


```bash
# Вход на сервер для openvpn
ssh \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_skv_VKR_vpn \
skv@158.160.201.144
```
```bash
# вход под сперпользователем YC ВМ
sudo su
```
```bash
# Обновление системы и установка easyrsa
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y easy-rsa tree \
&& systemctl reboot
```
```bash
# Генерация структуры каталогов PKI и генерация сертификата CA
cd /srv \
&& easyrsa init-pki \
&& easyrsa build-ca
```
```bash
# Группа Диффи-Хелмана
easyrsa gen-dh

# сертификат\ключ VPN-сервера
easyrsa build-server-full \
vkr \
nopass

# сертификат\ключ VPN-клиента
easyrsa build-client-full \
altwks1 \
nopass
```
```bash
# перенос генерации Диффи-Хелмана и пары сертификата\ключа для VPN-сервера
cp /srv/pki/{ca.crt,dh.pem} \
/srv/pki/{private,issued}/altwks1.* \
/home/skv/

chow skv:skv /home/skv/altwks1*
chow skv:skv /home/skv/{ca.crt,dh.pem}
```

```bash
# =====| Со стороны Altwks1 | ======
# перенос генерации Диффи-Хелмана и пары сертификата\ключа для VPN-сервера
# Копирование файлов
scp \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_skv_VKR_vpn \
skv@158.160.201.144:~/altwks1.* \
./

scp \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_skv_VKR_vpn \
skv@158.160.201.144:~/{ca.crt,dh.pem} \
./
```
```bash
# вход под суперпользователем
su -

# обновление системы и установка openvpn easy-rsa на клиенте соединения
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y \
openvpn \
easy-rsa
```
```bash
# Генерация Ключ HMAC
openvpn --genkey \
secret \
/etc/openvpn/keys/ta.key
```
```bash
# Копируем сгенерированный HMAC в домашний каталог для обмена через файловое облако между VPN-сервер\клиентом
cp /etc/openvpn/keys/ta.key \
/home/sysadmin/

# взаимодействовать с файлом на уровне пользователя
chown sysadmin:sysadmin \
/home/sysadmin/ta.key
```
```bash
# Копируем Генерацию Ключа HMAC на openvpn-server
scp \
-o StrictHostKeyChecking=accept-new \
-i /home/sysadmin/.ssh/id_skv_VKR_vpn \
/home/sysadmin/ta.key \
skv@158.160.201.144:~/ \
```
```bash
# Копирование всех необходимых файлов для настройки клиента
cp /home/sysadmin/{altwks1.*,ta.key,ca.crt,dh.pem} \
/etc/openvpn/keys/

# Выставление желательных прав для ключей\сертификатов
chmod -R 600 /etc/openvpn/keys
```
```bash
# Добавляем в hosts ip и имя внешнего сервера VPN 
# имя указанного хоста соответствует на чье имя был выписан сертификат из CA (openvpn-altserver)
sed -i '/**vkr$/d' /etc/hosts
echo "158.160.201.144 \
vkr" \
>> /etc/hosts
```
```bash
# Создание конфига туннельного соединения-клиента по subnet топологии
cat > /etc/openvpn/client/tun0.conf <<'EOF'
dev tun0
  client
  nobind
  remote vkr 1194
  proto udp4
  topology subnet
  pull
  cipher AES-256-CBC
  data-ciphers-fallback AES-256-CBC
  ca /etc/openvpn/keys/ca.crt
  cert /etc/openvpn/keys/altwks1.crt
  key /etc/openvpn/keys/altwks1.key
  tls-client
  remote-cert-eku "TLS Web Server Authentication"
  tls-auth /etc/openvpn/keys/ta.key 1
  auth-nocache
EOF
```
```bash
# Включение и запуск службы VPN-клиента
systemctl enable \
--now \
openvpn-client@tun0
```
```bash
# =====| На стороне сервера openVPN |=====
# Создание каталога для пары ключей и сертификатов
sudo mkdir -p \
/etc/openvpn/keys/

# Копирование подготовленных файлов пары ключей и сертификатов для сервера
cp pki/{issued,private}/vkr.* \
/srv/pki/{ca.crt,dh.pem} \
/etc/openvpn/keys/

# Копирование Ключа HMAC созданного с VPN-клиента
cp /home/skv/ta.key \
/etc/openvpn/keys/

sudo chown \
root:openvpn -R \
/etc/openvpn/keys

# Выставление желательных прав для ключей\сертификатов
chmod -R 600 \
/etc/openvpn/keys
```
```bash
# Создание конфига туннельного соединения-клиента по subnet топологии
sudo cat > /etc/openvpn/server/tun0.conf <<'EOF'
dev tun0
  local 10.10.10.254
  port 1194
  proto udp4
  keepalive 10 60
  topology subnet
  server 172.16.100.0 255.255.255.248
  data-ciphers-fallback AES-256-CBC
  cipher AES-256-CBC
  ca /etc/openvpn/keys/ca.crt
  dh /etc/openvpn/keys/dh.pem
  cert /etc/openvpn/keys/vkr.crt
  key /etc/openvpn/keys/vkr.key
  tls-server
  remote-cert-eku "TLS Web Client Authentication"
  tls-auth /etc/openvpn/keys/ta.key 0
EOF
```
```bash
# ЗАпуск службы
systemctl enable \
--now \
openvpn-server@tun0
```
```bash
# Проверка соединения
ping -c2 172.16.100.2
```
```
PING 172.16.100.2 (172.16.100.2) 56(84) bytes of data.
64 bytes from 172.16.100.2: icmp_seq=1 ttl=64 time=16.6 ms
64 bytes from 172.16.100.2: icmp_seq=2 ttl=64 time=16.2 ms

--- 172.16.100.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 16.166/16.386/16.606/0.220 ms
```
### SSH обмен ключами
```bash
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn

# копирование ключа на промежуточный сервер на YC
scp -v \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_skv_VKR_vpn.pub \
~/.ssh/id_skv_VKR_vp* \
skv@158.160.201.144:~/.ssh/

# Вход на промежуточный сервер с Openvpn
ssh \
-i ~/.ssh/id_skv_VKR_vpn \
-o StrictHostKeyChecking=accept-new \
skv@158.160.201.144

# Изменение прав 
chmod 640 \
~/.ssh/id_skv_VKR_vpn.pub
chmod 600 \
~/.ssh/id_skv_VKR_vpn

eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn

# проброс ключа до altwks1 через Openvpn
> ~/.ssh/known_hosts \
&& ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_skv_VKR_vpn.pub \
sysadmin@172.16.100.2
```

<details>
<summary>лог проброса ключа</summary>

```log
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/skv/.ssh/id_skv_VKR_vpn.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
Number of key(s) added: 1

Now try logging into the machine, with: "ssh -i /home/skv/.ssh/id_skv_VKR_vpn -o 'StrictHostKeyChecking=accept-new' 'sysadmin@172.16.100.2'"
and check to make sure that only the key(s) you wanted were added.
```

</details>

```bash
# копирование ключа на удаленный хост клиента openvpn
scp -v \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_skv_VKR_vpn.pub \
~/.ssh/id_skv_VKR_vp* \
sysadmin@172.16.100.2:~/.ssh/

# Выход с сервера openvpn-server
exit
```
```bash
# вход на удаленный хост по ключу по ssh через yandex cloud
> ~/.ssh/known_hosts \
&& ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J skv@158.160.201.144 \
-o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"hostname && hostname -i"
```
```log
altwks1
192.168.1.186 192.168.100.1 172.16.100.2
Connection to 172.16.100.2 closed.
```
### Подготовка Управляющего узла
```bash
# вход на bastion хост по ключу по ssh через yandex cloud
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J skv@158.160.201.144 \
-o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"su -"

# Смена прав на использование ssh ключей
chown -v sysadmin:sysadmin \
/home/sysadmin/.ssh/id_skv_VKR_vp* \
&& chmod -v 600 \
/home/sysadmin/.ssh/id_skv_VKR_vpn \
&& chmod -v 640 \
/home/sysadmin/.ssh/id_skv_VKR_vpn.pub
```

<details>
<summary>Лог смены прав ssh ключей</summary>

```log
ownership of '/home/sysadmin/.ssh/id_skv_VKR_vpn' retained as sysadmin:sysadmin
ownership of '/home/sysadmin/.ssh/id_skv_VKR_vpn.pub' retained as sysadmin:sysadmin
mode of '/home/sysadmin/.ssh/id_skv_VKR_vpn' retained as 0600 (rw-------)
mode of '/home/sysadmin/.ssh/id_skv_VKR_vpn.pub' changed from 0644 (rw-r--r--) to 0640 (rw-r-----)
```

</details>

```bash
# Обновление и установка необходимых пакетов Управляющему узлу
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install ansible sshpass -y \
&& apt-get autoremove -y \
&& systemctl reboot
```
### Подготовка Управляемых узлов
#### Проброс ключей для работы ansible
```bash
# вход на bastion хост по ключу по ssh через yandex cloud
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J skv@158.160.201.144 \
-o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"su -"

# проброс ключа до Управляемых хостов
> ~/.ssh/known_hosts
for ip in {2,11,12,13,14}; do \
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i /home/sysadmin/.ssh/id_skv_VKR_vpn.pub \
sysadmin@192.168.100.$ip; done
```
<details>
<summary>Вывод Проброса ключей</summary>

```log
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/sysadmin/.ssh/id_skv_VKR_vpn.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.2's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -o 'StrictHostKeyChecking=accept-new' 'sysadmin@192.168.100.2'"
and check to make sure that only the key(s) you wanted were added.

/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/sysadmin/.ssh/id_skv_VKR_vpn.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.11's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -o 'StrictHostKeyChecking=accept-new' 'sysadmin@192.168.100.11'"
and check to make sure that only the key(s) you wanted were added.

/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/sysadmin/.ssh/id_skv_VKR_vpn.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.12's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -o 'StrictHostKeyChecking=accept-new' 'sysadmin@192.168.100.12'"
and check to make sure that only the key(s) you wanted were added.

/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/sysadmin/.ssh/id_skv_VKR_vpn.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.13's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -o 'StrictHostKeyChecking=accept-new' 'sysadmin@192.168.100.13'"
and check to make sure that only the key(s) you wanted were added.

/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/sysadmin/.ssh/id_skv_VKR_vpn.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.14's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -o 'StrictHostKeyChecking=accept-new' 'sysadmin@192.168.100.14'"
and check to make sure that only the key(s) you wanted were added.
```

</details>

#### Установка необходимых пакетов на управляемых хостах
```bash
# Установка пакетов с заранее известных хостов
for ip in {2,11,12,13,14}; do \
ssh -t \
-i /home/sysadmin/.ssh/id_skv_VKR_vpn \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100."$ip" \
"su -c 'apt-get update \
&& apt-get install -y \
python3 \
python3-module-yaml \
python3-module-jinja2 \
python3-module-jsonobject \
&& systemctl reboot'" ; done
```

### Формирование Структуры папок и файлов
#### Создание общей коллекции
```bash
# создании структуры коллекции Ansible
ansible-galaxy collection \
init \
VKR.ans_vkr_skv
```
```log
- Collection VKR.ans_vkr_skv was created successfully
```
#### создание ролей
```bash
#  Вход в namespace коллекции Ansible
cd VKR/

# Переименование коллекции Ansible
mv ans_vkr_skv \
7.Ansible_automation

# Создание ролей ansible
for r in {base_setup,chrony_sync,samba_ad_dc,dhcp_server,smb_shares,nfs_server,squid_proxy,sysvol_replication,monitoring_scripts}; do \
ansible-galaxy role \
init \
roles/$r \
; done
```

<details>
<summary>Лог вывода о создании ролей</summary>

```log
- Role roles/base_setup was created successfully
- Role roles/chrony_sync was created successfully
- Role roles/samba_ad_dc was created successfully
- Role roles/dhcp_server was created successfully
- Role roles/smb_shares was created successfully
- Role roles/nfs_server was created successfully
- Role roles/squid_proxy was created successfully
- Role roles/sysvol_replication was created successfully
- Role roles/monitoring_scripts was created successfully
```

</details>

#### Настройка конфигурации ansible локального проекта
```bash
# создание локального файла конфигурации ansible
cat > ansible.cfg <<'EOF'
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
EOF

# создание каталога inventory и глобальных переменных для хостов
mkdir -vp inventory/{group_vars,host_vars}

mkdir -vp inventory/group_vars/all

# Для nfs сетевого хранилища и отключения сообщения
# "Ansible is being run in a world writable directory ...
# ignoring it as an ansible.cfg source"
export ANSIBLE_CONFIG=./ansible.cfg
```

#### Создаем файл Управляемых хостов
```bash
cat > ./inventory/hosts.ini << 'EOF'
[domain_controllers]
altsrv2 ansible_host=192.168.100.12
altsrv3 ansible_host=192.168.100.13

[file_servers]
altsrv4 ansible_host=192.168.100.14

[proxy_servers]
altsrv1 ansible_host=192.168.100.11
EOF
```

#### создание переменных для всех групп в 
```bash
cat > inventory/group_vars/all.yml <<'EOF'
---
# параметры суперпользователя
ansible_ssh_private_key_file: " ~/.ssh/id_skv_VKR_vpn"
ansible_user: "{{ vault_su_wheel_user }}"
ansible_become_password: "{{ vault_su_password }}"

# Общие параметры домена
ad_workgroup: "den.skv"
ad_realm: "DEN.SKV"
ad_domain: "DEN"
ad_admin_user: "Administrator"
ad_admin_password: "{{ vault_ad_admin_password }}"
primary_dc: "{{ groups['domain_controllers'][0] }}"
primary_dc_ip: "{{ hostvars[primary_dc]['ansible_host'] }}"
secondary_dc: "{{ groups['domain_controllers'][1] }}"
secondary_dc_ip: "{{ hostvars[secondary_dc]['ansible_host'] }}"

# Сеть
network_subnet: "192.168.100.0"
network_netmask: "255.255.255.0"
network_gateway: "192.168.100.1"
...
EOF
```

```bash
# Archlinux
# Генерация пароля (pwgen) и запись значения в файл 
# для доступа к зашифрованному файлу переменных vault.yml
# Создание зашифрованного файла vault.yml с паролями
# и переход сразу к редактированию
tee ./va_pa <<< $(pwgen -1) \
&& chmod -x ./va_pa \
&& EDITOR=nano \
ansible-vault create \
--encrypt-vault-id default \
--vault-password-file ./va_pa \
./inventory/group_vars/all/vault.yml
```

<details>
<summary>Содержимое vault</summary>

```yaml
---
vault_ad_admin_password: "1qaz@WSX"
vault_omapi_secret: "KsP/KnIQcoQF5fMMjBcOhg=="
vault_su_wheel_user: sysadmin
vault_su_password: netlab123
...
```

</details>

##### Команда вызова редактирования файла с паролями
```bash
EDITOR=nano \
ansible-vault edit \
./inventory/group_vars/all/vault.yml \
--vault-password-file ./va_pa
```
### создание основы главного playbook
```bash
cat > ./main.yaml<< 'EOF'
#!/usr/bin/env ansible-playbook
---
- name: Развертывание гибридной инфраструктуры
  hosts: all
  become: true
  become_method: su
  become_user: root
  gather_facts: true
  vars:
    # включаем(true)\выключаем(false)
    base_setup: true
    # Отдельные задачи включения пакетов
    dist_upd: true # Обновление кеша пакетов
    dist_upgrd: true # обновление установленных приложений
    kernel_upd: true # обновление ядра

    chrony_sync: true
    samba_ad_dc: true
    dhcp_server: false
    sysvol_replication: false
    kerberos_client: false
    smb_shares: false
    nfs_server: false
    squid_proxy: false
    monitoring_scripts: false

- name: Базовая настройка хостов
  import_playbook: base_setup.yaml
  when: base_setup | bool

- name: Настройка синхронизации времени
  import_playbook: chrony_sync.yaml
  when: chrony_sync | bool

- name: Установка Samba Active Directory DC
  import_playbook: samba_ad_dc.yaml
  when: samba_ad_dc | bool

- name: DHCP с failover и DDNS
  import_playbook: dhcp_server.yaml
  when: dhcp_server | bool

- name: Репликация SysVol между DC
  import_playbook: squid_proxy.yaml
  when: squid_proxy | bool

- name: Smb файловый сервер
  import_playbook: smb_shares.yaml
  when: smb_shares | bool

- name: NFS с Kerberos
  import_playbook: nfs_server.yaml
  when: nfs_server | bool

- name: SQUID с Kerberos-аутентификацией
  import_playbook: squid_proxy.yaml
  when: squid_proxy | bool

- name: Скрипты мониторинга и failover
  import_playbook: monitoring_scripts.yaml
  when: monitoring_scripts | bool
...
EOF
```
### playbook базовых настроек хостов
```bash
cat > ./base_setup.yaml << 'EOF'
#!/usr/bin/env ansible-playbook
---
- name: Базовая настройка хостов
  hosts: all
  become: true
  become_method: su
  become_user: root
  roles:
    - base_setup
...
EOF
```
#### Главный файл задач базовых настроек
```bash
cat > roles/base_setup/tasks/main.yml <<'EOF'
---
- name: Обновление кеша пакетов
  apt_rpm:
    update_cache: true
  when: dist_upd | bool

- name: Установка базовых пакетов при вводе в домен
  apt_rpm:
    name:
      - task-auth-ad-sssd
      - chrony
      - samba-common-tools
      - samba-client
    state: installed
  when:
    - inventory_hostname not in groups['domain_controllers']
    - dist_upd | bool

- name: Обновление пакетов
  apt_rpm:
    dist_upgrade: true
  when: dist_upgrd | bool

- name: Обновление ядра
  apt_rpm:
    update_kernel: true
  environment:
    PATH: "{{ ansible_env.PATH }}:/usr/sbin"
  ignore_errors: true
  when: kernel_upd | bool

- name: Установка имени хоста
  hostname:
    name: "{{ inventory_hostname }}.{{ ad_workgroup }}"
    
- name: Определить основной интерфейс
  set_fact:
    primary_iface_name: >-
      {{
          ansible_interfaces
          | difference(['lo'])
          | select('match', '^(eth|en)[a-z0-9]*')
          | first
      }}

- name: Настройка DNS резолвера
  template:
    src: resolv.conf.j2
    dest: "/etc/net/ifaces/{{ primary_iface_name }}/resolv.conf"
  when:
    - inventory_hostname not in groups['domain_controllers']
    
- name: Отключение IPv6
  sysctl:
    name: net.ipv6.conf.all.disable_ipv6
    value: "1"
    state: present
...
EOF
```

#### Файл переменных по умолчанию роли базовых настроек
```bash
cat > roles/base_setup/defaults/main.yml <<'EOF'
---
dist_upd: true # Обновление кеша пакетов
dist_upgrd: true # обновление установленных приложений
kernel_upd: true # обновление ядра
...
EOF
```
#### Шаблон resolver роли базовых настроек
```bash
cat > roles/base_setup/templates/resolv.conf.j2 <<'EOF'
{% for server in groups.domain_controllers %}
nameserver {{ hostvars[server].ansible_host }}
{% endfor %}
search {{ ad_workgroup }}
options rotate
EOF
```

### `chrony_sync` - Синхронизация времени
```bash
cat > ./chrony_sync.yaml << 'EOF'
#!/usr/bin/env ansible-playbook
---
- name: Настройка синхронизации времени
  hosts: all
  become: true
  become_method: su
  become_user: root
  roles:
    - chrony_sync
...
EOF
```

#### Главный файл задач Синхронизация времени
```bash
cat > roles/chrony_sync/tasks/main.yml <<'EOF'
---
- name: Обновление кеша пакетов
  apt_rpm:
    update_cache: true

- name: Установка базовых пакетов при вводе в домен
  apt_rpm:
    name:
      - chrony
    state: installed
    
- name: Настройка chrony.conf для основного DC
  template:
    src: chrony.conf.dc_main.j2
    dest: /etc/chrony.conf
    backup: true
  notify: Restart chronyd
  when:
  - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: Настройка chrony.conf для вторичного DC
  template:
    src: chrony.conf.dc_second.j2
    dest: /etc/chrony.conf
    backup: true
  notify: Restart chronyd
  when:
  - inventory_hostname == (groups['domain_controllers'] | list)[1]

- name: Настройка chrony.conf для пользователей домена
  template:
    src: chrony.conf.members.j2
    dest: /etc/chrony.conf
    backup: true
  notify: Restart chronyd
  when:
  - inventory_hostname not in groups['domain_controllers']

- name: Запуск и включение службы chronyd
  systemd:
    name: "{{ item }}"
    state: started
    enabled: true
    masked: false
    daemon_reload: true
  loop:
    - chronyd
...
EOF
```
#### Шаблоны сервера времени роли Синхронизация времени
##### Для основного сервера времени
```bash
cat > roles/chrony_sync/templates/chrony.conf.dc_main.j2 <<'EOF'
server {{ exter_ntp }} iburst
{% for host in groups['domain_controllers'] %}
{% if inventory_hostname != host %}
server {{ host }}.{{ ad_workgroup }} iburst
{% endif %}
{% endfor %}
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow {{ allow_clients }}
local stratum 10
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
EOF
```
##### Для вторичного сервера времени
```bash
cat > roles/chrony_sync/templates/chrony.conf.dc_second.j2 <<'EOF'
{% for host in groups['domain_controllers'] %}
{% if inventory_hostname != host %}
server {{ host }}.{{ ad_workgroup }} iburst
{% endif %}
{% endfor %}
server {{ exter_ntp }} iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow {{ allow_clients }}
local stratum 10
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
EOF
```
##### Для пользователей домена
```bash
cat > roles/chrony_sync/templates/chrony.conf.members.j2 <<'EOF'
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
{% for host in groups['domain_controllers'] %}
server {{ host }}.{{ ad_workgroup }} iburst
{% endfor %}
EOF
```

#### Обработчики роли Синхронизация времени
```bash
cat > roles/chrony_sync/handlers/main.yml <<'EOF'
---
- name: Перезапуск chronyd обработчиком
  systemd:
    name: "{{ item }}"
    state: restarted
    enabled: true
    masked: false
    daemon_reload: true
  loop:
    - chronyd
  listen: Restart chronyd
...
EOF
```
### Переменные по умолчанию
```bash
cat > roles/chrony_sync/defaults/main.yml<<'EOF'
---
exter_ntp: ntp3.vniiftri.ru
allow_clients: "192.168.100.0/24"
...
EOF
```

### `samba_ad_dc` - Контроллер домена Active Directory
```bash
cat > ./samba_ad_dc.yaml << 'EOF'
#!/usr/bin/env ansible-playbook
---
- name: Samba Active Directory DC
  hosts: domain_controllers
  become: true
  become_method: su
  become_user: root
  roles:
    - samba_ad_dc
...
EOF
```

#### Главный файл задач роли Контроллер домена Active Directory
```bash
cat > roles/samba_ad_dc/tasks/main.yml <<'EOF'
---
- name: Базовая подготовка серверов AD
  include_tasks: base.yml
  when:
    - inventory_hostname in groups['domain_controllers']

- name: Развертывание основного домен контролера
  include_tasks: primary_dc.yml
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: Развертывание вторичного домен контролера
  include_tasks: second_dc.yml
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[1]
    - sysvol_replication | bool
...
EOF
```

#### Файл базовых задач роли Контроллер домена Active Directory
```bash
cat > roles/samba_ad_dc/tasks/base.yml <<'EOF'
---
- name: Остановка конфликтующих служб
  systemd:
    name: "{{ item }}"
    state: stopped
    masked: true
    enabled: false
  loop: 
    - smb
    - nmb
    - krb5kdc
    - slapd
    - bind
    - dnsmasq

- name: Обновление кеша пакетов
  apt_rpm:
    update_cache: true

- name: Установка пакетов Samba DC
  apt_rpm:
    name:
      - task-samba-dc
      - alterator-net-domain
      - alterator-datetime
    state: present
    
- name: Очистка дефолтных конфигов Samba
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - /etc/samba/smb.conf
    - /var/lib/samba
    - /var/cache/samba

- name: создание каталога для работы Домена
  file:
    path: /var/lib/samba/sysvol
    state: directory

- name: Определить основной интерфейс
  set_fact:
    primary_iface_name: >-
      {{
          ansible_interfaces
          | difference(['lo'])
          | select('match', '^(eth|en)[a-z0-9]*')
          | first
      }}
...
EOF
```

#### Файл задач развертывания основного DC роли Контроллер домена Active Directory
```bash
cat > roles/samba_ad_dc/tasks/primary_dc.yml <<'EOF'
---
- name: Provisioning основного домен-контроллера
  command: >
    samba-tool domain provision
    --realm={{ ad_realm }}
    --domain={{ ad_domain }}
    --server-role=dc
    --dns-backend="{{ ad_backend }}"
    --use-rfc2307
    --function-level="{{ func_level }}"
    --adminpass='{{ ad_admin_password }}'
    --option="dns forwarder={{ dns_forwarder }}"
    --option="interfaces= lo {{ primary_iface_name }}"
    --option="bind interfaces only=yes"
    --option="dns zone scavenging=yes"
    --option="allow dns updates=secure only"
  args:
    creates: /var/lib/samba/private/sam.ldb

- name: Запуск samba AD сервер
  systemd:
    name: "{{ item }}"
    state: started
    masked: false
    enabled: true
  loop: 
    - samba

- name: Очистка с интервалом обновления 30 дней
  command: >
    samba-tool dns zoneoptions
    {{ inventory_hostname }}
    {{ ad_realm }}
    --aging=1
    --refreshinterval={{ dns_refresh }}
    -U'{{ ad_admin_user }}%{{ ad_admin_password }}'

- name: Создание обратной - PTR зоны
  command: >
    samba-tool dns zonecreate
    {{ inventory_hostname }}
    {{ ptr_zone }}
    -U'{{ ad_admin_user }}%{{ ad_admin_password }}'

- name: Добавление записи типа PTR для обратной зоны самого домен контролера
  command: >
    samba-tool dns add
    {{ inventory_hostname }}
    {{ ptr_zone }}
    {{ ptr_ip_main_dc }} PTR
    {{ inventory_hostname }}
    -U'{{ ad_admin_user }}%{{ ad_admin_password }}'

- name: Добавление А записи для вторичного контролера
  command: >
    samba-tool dns add
    {{ inventory_hostname }}
    {{ ad_workgroup }}
    {{ secondary_dc | upper }}
    A
    {{ secondary_dc_ip }}
    -U'{{ ad_admin_user }}%{{ ad_admin_password }}'
  when:
    - sysvol_replication | bool

- name: Добавление записи типа PTR для обратной зоны вторичного домен контролера
  command: >
    samba-tool dns add
    {{ inventory_hostname }}
    {{ ptr_zone }}
    {{ ptr_ip_second_dc }} PTR
    {{ secondary_dc }}.{{ ad_workgroup }}
    -U'{{ ad_admin_user }}%{{ ad_admin_password }}'
  when:
    - sysvol_replication | bool

- name: Настройка DNS резолвера основного DC
  template:
    src: resolv.conf_dc_main.j2
    dest: "/etc/net/ifaces/{{ primary_iface_name }}/resolv.conf"
  notify:
    - restart network
    - restart interface

- name: Заменяем настройки Kerberos для клиентского обращение
  copy:
    src: "/var/lib/samba/private/krb5.conf"
    dest: "/etc/krb5.conf"
    backup: true
...
EOF
```

#### Файл задач развертывания вторичного DC роли Контроллер домена Active Directory
```bash
cat > roles/samba_ad_dc/tasks/second_dc.yml <<'EOF'
---
- name: Определить основной интерфейс вторичного DC
  set_fact:
    primary_iface_name: >-
      {{
          ansible_interfaces
          | difference(['lo'])
          | select('match', '^(eth|en)[a-z0-9]*')
          | first
      }}

- name: Настройка chrony.conf для вторичного DC
  template:
    src: krb5.conf.dc_second.j2
    dest: /etc/krb5.conf
    backup: true

- name: Получаем kerberos билет на имя входящего в доменную группу Domain Admins
  shell: printf '%s\n' '{{ ad_admin_password }}' | kinit Administrator

- name: Присоединение вторичного контроллера домена
  command: >
    samba-tool domain join
    {{ ad_realm }}
    DC
    -U'{{ ad_admin_user }}%{{ ad_admin_password }}'
    --realm={{ ad_realm }}
    --option="ad dc functional level={{ func_level }}"
    --option="dns forwarder={{ dns_forwarder }}"
    --option='idmap_ldb:use rfc2307 = yes'
    --option="interfaces= lo {{ primary_iface_name }}"
    --option="bind interfaces only=yes"
    --option="dns zone scavenging=yes"
    --option="allow dns updates=secure only"
  args:
    creates: /var/lib/samba/private/secrets.tdb
  
- name: Запуск samba AD сервер
  systemd:
    name: "{{ item }}"
    state: started
    masked: false
    enabled: true
  loop: 
    - samba

- name: Настройка DNS резолвера дополнительного DC
  template:
    src: resolv.conf_dc_second.j2
    dest: "/etc/net/ifaces/{{ primary_iface_name }}/resolv.conf"
  notify:
    - restart network dc2
    - restart interface dc2

- name: Репликация с первого контроллера домена на второй
  command: >
    samba-tool drs replicate 
    {{ inventory_hostname }}.{{ ad_workgroup }}
    {{ primary_dc }}.{{ ad_workgroup }}
    {{ ldap_search }}
    -U'{{ ad_admin_user }}%{{ ad_admin_password }}'
...
EOF
```
#### Шаблон kerberos роли домен контроллеров
```bash
cat > roles/samba_ad_dc/templates/resolv.conf_dc_main.j2 <<'EOF'
cat /etc/krb5.conf
includedir /etc/krb5.conf.d/
[logging]
[libdefaults]
 dns_lookup_kdc = true
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = {{ ad_realm }}
 default_ccache_name = KEYRING:persistent:%{uid}
[realms]
[domain_realm]
EOF
```

#### Шаблон resolver роли домен контроллеров
##### Шаблон resolver для основного DC
```bash
cat > roles/samba_ad_dc/templates/resolv.conf_dc_main.j2 <<'EOF'
nameserver 127.0.0.1
{% for server in groups.domain_controllers %}
{% if inventory_hostname != host %}
nameserver {{ hostvars[server].ansible_host }}
{% endif %}
{% endfor %}
search {{ ad_workgroup }}
EOF
```

##### Шаблон resolver для вторичного DC
```bash
cat > roles/samba_ad_dc/templates/resolv.conf_dc_second.j2 <<'EOF'
nameserver 127.0.0.1
{% for server in groups.domain_controllers %}
{% if inventory_hostname != host %}
nameserver {{ hostvars[server].ansible_host }}
{% endif %}
{% endfor %}
search {{ ad_workgroup }}
EOF
```

#### Переменные по умолчанию
```bash
cat > roles/samba_ad_dc/defaults/main.yml<<'EOF'
---
func_level: 2016
ad_backend: 'SAMBA_INTERNAL'
dns_refresh: 720
ptr_zone: "100.168.192.in-addr.arpa"
ptr_ip_main_dc: 12
ptr_ip_second_dc: 13
ldap_search: "dc=den,dc=skv"
...
EOF
```
#### Обработчики роли Контроллера домена
```bash
cat > roles/samba_ad_dc/handlers/main.yml <<'EOF'
---
- name: Перезапуск сетевых служб основного dc
  systemd:
    name: "{{ item }}"
    state: restarted
    enabled: true
    masked: false
    daemon_reload: true
  listen: "restart network"
  async: 10
  poll: 0
  loop:
    - network
    - samba
  ignore_unreachable: true
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: перезапуск интерфейса основного dc
  shell: ifdown {{ ansible_interfaces }} && ifup {{ ansible_interfaces }}
  listen: "restart interface"
  async: 10
  poll: 0
  ignore_unreachable: true
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: Перезапуск сетевых служб основного dc
  systemd:
    name: "{{ item }}"
    state: restarted
    enabled: true
    masked: false
    daemon_reload: true
  listen: "restart network dc2"
  async: 10
  poll: 0
  loop:
    - network
    - samba
  ignore_unreachable: true
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[1]

- name: перезапуск интерфейса основного dc
  shell: ifdown {{ ansible_interfaces }} && ifup {{ ansible_interfaces }}
  listen: "restart interface dc2"
  async: 10
  poll: 0
  ignore_unreachable: true
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[1]
...
EOF
```

### `dhcp_server` - DHCP с failover и DDNS
```bash
cat > ./dhcp_server.yaml << 'EOF'
#!/usr/bin/env ansible-playbook
---
- name: DHCP с failover и DDNS
  hosts: domain_controllers
  become: true
  become_method: su
  become_user: root
  roles:
    - dhcp_server
...
EOF
```

#### Главный файл задач роли DHCP
```bash
cat > roles/dhcp_server/tasks/main.yml <<'EOF'
---
- name: Обновление кеша пакетов
  apt_rpm:
    update_cache: true

- name: Установка пакетов Samba DC
  apt_rpm:
    name: 
      - dhcp-server
    state: present

- name: Создание пользователя для DDNS
  command: >
    samba-tool user create
    {{ dhcpduser }}
    --description="Пользователь обновления DNS через DHCP-сервер
    --random-password
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: Добавление пользователя в группу DnsAdmins
  command: >
    samba-tool group addmembers
    'DnsAdmins'
    {{ dhcpduser }}
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: Включить пользователя {{ dhcpduser }}
  command: >
    samba-tool user setexpiry
    {{ dhcpduser }}
    --noexpiry
  when:
    - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: Экспорт файла keytab
  command: >
    samba-tool domain exportkeytab
    --principal={{ dhcpduser }}@"{{ ad_realm }}"
    {{ keytab_export_path }}
  args:
    creates: {{ keytab_export_path }}

- name: Изменение прав на файл kerberos пользователя {{ dhcpduser }}
  file:
    path: {{ keytab_export_path }}
    owner: dhcpd
    group: dhcp
    mode: '0400'

- name: Развертывание скрипта обновления DNS
  template:
    src: dhcp-dyndns.sh.j2
    dest: /usr/local/bin/dhcp-dyndns.sh
    mode: '0755' 

- name: Развертывание конфигурации dhcpd.conf
  template:
    src: dhcpd.conf.j2
    dest: /etc/dhcp/dhcpd.conf
    validate: dhcpd -t -cf %s
  notify: Restart dhcpd
  when:
    - not sysvol_replication | bool

- name: Развертывание конфигурации dhcpd.conf под failover
  template:
    src: dhcpd_failover_primary.conf.j2
    dest: /etc/dhcp/dhcpd.conf
    validate: dhcpd -t -cf %s
  notify: Restart dhcpd
  when:
    - sysvol_replication | bool
    - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: Развертывание конфигурации dhcpd.conf под failover
  template:
    src: dhcpd_failover_second.conf.j2
    dest: /etc/dhcp/dhcpd.conf
    validate: dhcpd -t -cf %s
  notify: Restart dhcpd
  when:
    - sysvol_replication | bool
    - inventory_hostname == (groups['domain_controllers'] | list)[1]
...
EOF
```

#### Шаблоны конфигурационного файла роли DHCP
##### Шаблон файла-скрипта для DDNS
```bash
cat > roles/dhcp_server/templates/dhcp-dyndns.sh.j2 <<'EOT'
#!/bin/bash
#
# This script is for secure DDNS updates on Samba,
# it can also add the 'macAddress' to the Computers object.
#
# Version: 0.9.6
#

##########################################################################
#                                                                        #
#    You can optionally add the 'macAddress' to the Computers object.    #
#    Add 'dhcpduser' to the 'Domain Admins' group if used                #
#    Change the next line to 'yes' to make this happen                   #
Add_macAddress='no'
#                                                                        #
##########################################################################

keytab=/etc/dhcp/dhcpduser.keytab

usage()
{
  cat <<-EOF
  USAGE:
    $(basename "$0") add ip-address dhcid|mac-address hostname
    $(basename "$0") delete ip-address dhcid|mac-address
EOF
}

_KERBEROS()
{
  # get current time as a number
  test=$(date +%d'-'%m'-'%y' '%H':'%M':'%S)
  # Note: there have been problems with this
  # check that 'date' returns something like

  # Check for valid kerberos ticket
  #logger "${test} [dyndns] : Running check for valid kerberos ticket"
  klist -c "${KRB5CCNAME}" -s
  ret="$?"
  if [ $ret -ne 0 ]
  then
    logger "${test} [dyndns] : Getting new ticket, old one has expired"
    kinit -F -k -t $keytab "${SETPRINCIPAL}"
    ret="$?"
    if [ $ret -ne 0 ]
    then
      logger "${test} [dyndns] : dhcpd kinit for dynamic DNS failed"
      exit 1
    fi
  fi
}

rev_zone_info()
{
  local RevZone="$1"
  local IP="$2"
  local rzoneip
  rzoneip="${RevZone%.in-addr.arpa}"
  local rzonenum
  rzonenum=$(echo "$rzoneip" |  tr '.' '\n')
  declare -a words
  for n in $rzonenum
  do
    words+=("$n")
  done
  local numwords="${#words[@]}"

  unset ZoneIP
  unset RZIP
  unset IP2add

  case "$numwords" in
    1)
      # single ip rev zone '192'
      ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1}')
      RZIP="${rzoneip}"
      IP2add=$(echo "${IP}" | awk -F '.' '{print $4"."$3"."$2}')
      ;;
    2)
      # double ip rev zone '168.192'
      ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1"."$2}')
      RZIP=$(echo "${rzoneip}" | awk -F '.' '{print $2"."$1}')
      IP2add=$(echo "${IP}" | awk -F '.' '{print $4"."$3}')
      ;;
    3)
      # triple ip rev zone '0.168.192'
      ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1"."$2"."$3}')
      RZIP=$(echo "${rzoneip}" | awk -F '.' '{print $3"."$2"."$1}')
      IP2add=$(echo "${IP}" | awk -F '.' '{print $4}')
      ;;
    *)
      # should never happen
      exit 1
      ;;
  esac
}

BINDIR=$(samba -b | grep 'BINDIR' | grep -v 'SBINDIR' | awk '{print $NF}')
[[ -z $BINDIR ]] && printf "Cannot find the 'samba' binary, is it installed ?\\nOr is your path set correctly ?\\n"
WBINFO="$BINDIR/wbinfo"

SAMBATOOL=$(command -v samba-tool)
[[ -z $SAMBATOOL ]] && printf "Cannot find the 'samba-tool' binary, is it installed ?\\nOr is your path set correctly ?\\n"

MINVER=$($SAMBATOOL -V | grep -o '[0-9]*' | tr '\n' ' ' | awk '{print $2}')
if [ "$MINVER" -gt '14' ]
then
  KTYPE="--use-kerberos=required"
else
  KTYPE="-k yes"
fi

# DHCP Server hostname
Server=$(hostname -s)

# DNS domain
domain=$(hostname -d)
if [ -z "${domain}" ]
then
  logger "Cannot obtain domain name, is DNS set up correctly?"
  logger "Cannot continue... Exiting."
  exit 1
fi

# Samba realm
REALM="${domain^^}"

# krbcc ticket cache
export KRB5CCNAME="/tmp/dhcp-dyndns.cc"

# Kerberos principal
SETPRINCIPAL="dhcpduser@${REALM}"
# Kerberos keytab as above
# krbcc ticket cache : /tmp/dhcp-dyndns.cc
TESTUSER="$($WBINFO -u | grep 'dhcpduser')"
if [ -z "${TESTUSER}" ]
then
  logger "No AD dhcp user exists, need to create it first.. exiting."
  logger "you can do this by typing the following commands"
  logger "kinit Administrator@${REALM}"
  logger "$SAMBATOOL user create dhcpduser --random-password --description='Unprivileged Пользователь обновления DNS через DHCP-сервер'"
  logger "$SAMBATOOL user setexpiry dhcpduser --noexpiry"
  logger "$SAMBATOOL group addmembers DnsAdmins dhcpduser"
  exit 1
fi

# Check for Kerberos keytab
if [ ! -f "$keytab" ]
then
  logger "Required keytab $keytab not found, it needs to be created."
  logger "Use the following commands as root"
  logger "$SAMBATOOL domain exportkeytab --principal=${SETPRINCIPAL} $keytab"
  logger "chown dhcpd:dhcp $keytab"
  logger "Replace 'dhcpd:dhcp' with the user & group that dhcpd runs as on your distro"
  logger "chmod 400 $keytab"
  exit 1
fi

# Variables supplied by dhcpd.conf
action="$1"
ip="$2"
DHCID="$3"
name="${4%%.*}"

# Exit if no ip address
if [ -z "${ip}" ]
then
  usage
  exit 1
fi

# Exit if no computer name supplied, unless the action is 'delete'
if [ -z "${name}" ]
then
  if [ "${action}" = "delete" ]
  then
    name=$(host -t PTR "${ip}" | awk '{print $NF}' | awk -F '.' '{print $1}')
  else
    usage
    exit 1
  fi
fi

# exit if name contains a space
case ${name} in
  *\ * )
    logger "Invalid hostname '${name}' ...Exiting"
    exit
    ;;
esac

# if you want computers with a hostname that starts with 'dhcp' in AD
# comment the following block of code.
if [[ $name == dhcp* ]]
then
  logger "not updating DNS record in AD, invalid name"
  exit 0
fi

## update ##
case "${action}" in
  add)
    _KERBEROS
    count=0
    # does host have an existing 'A' record ?
    mapfile -t A_REC < <($SAMBATOOL dns query "${Server}" "${domain}" "${name}" A "$KTYPE" 2>/dev/null | grep 'A:' | awk '{print $2}')
    if [ "${#A_REC[@]}" -eq 0 ]
    then
      # no A record to delete
      result1=0
      $SAMBATOOL dns add "${Server}" "${domain}" "${name}" A "${ip}" "$KTYPE"
      result2="$?"
    elif [ "${#A_REC[@]}" -gt 1 ]
    then
      for i in "${A_REC[@]}"
      do
        $SAMBATOOL dns delete "${Server}" "${domain}" "${name}" A "${i}" "$KTYPE"
      done
      # all A records deleted
      result1=0
      $SAMBATOOL dns add "${Server}" "${domain}" "${name}" A "${ip}" "$KTYPE"
      result2="$?"
    elif [ "${#A_REC[@]}" -eq 1 ]
    then
      # turn array into a variable
      VAR_A_REC="${A_REC[*]}"
      if [ "$VAR_A_REC" = "${ip}" ]
      then
        # Correct A record exists, do nothing
        logger "Correct 'A' record exists, not updating."
        result1=0
        result2=0
        count=$((count+1))
      elif [ "$VAR_A_REC" != "${ip}" ]
      then
        # Wrong A record exists
        logger "'A' record changed, updating record."
        $SAMBATOOL dns delete "${Server}" "${domain}" "${name}" A "${VAR_A_REC}" "$KTYPE"
        result1="$?"
        $SAMBATOOL dns add "${Server}" "${domain}" "${name}" A "${ip}" "$KTYPE"
        result2="$?"
      fi
    fi

    # get existing reverse zones (if any)
    ReverseZones=$($SAMBATOOL dns zonelist "${Server}" "$KTYPE" --reverse | grep 'pszZoneName' | awk '{print $NF}')
    if [ -z "$ReverseZones" ]; then
      logger "No reverse zone found, not updating"
      result3='0'
      result4='0'
      count=$((count+1))
    else
      for revzone in $ReverseZones
      do
        rev_zone_info "$revzone" "${ip}"
        if [[ ${ip} = $ZoneIP* ]] && [ "$ZoneIP" = "$RZIP" ]
        then
          # does host have an existing 'PTR' record ?
          PTR_REC=$($SAMBATOOL dns query "${Server}" "${revzone}" "${IP2add}" PTR "$KTYPE" 2>/dev/null | grep 'PTR:' | awk '{print $2}' | awk -F '.' '{print $1}')
          if [[ -z $PTR_REC ]]
          then
            # no PTR record to delete
            result3=0
            $SAMBATOOL dns add "${Server}" "${revzone}" "${IP2add}" PTR "${name}"."${domain}" "$KTYPE"
            result4="$?"
            break
          elif [ "$PTR_REC" = "${name}" ]
          then
            # Correct PTR record exists, do nothing
            logger "Correct 'PTR' record exists, not updating."
            result3=0
            result4=0
            count=$((count+1))
            break
          elif [ "$PTR_REC" != "${name}" ]
          then
            # Wrong PTR record exists
            # points to wrong host
            logger "'PTR' record changed, updating record."
            $SAMBATOOL dns delete "${Server}" "${revzone}" "${IP2add}" PTR "${PTR_REC}"."${domain}" "$KTYPE"
            result3="$?"
            $SAMBATOOL dns add "${Server}" "${revzone}" "${IP2add}" PTR "${name}"."${domain}" "$KTYPE"
            result4="$?"
            break
          fi
        else
          continue
        fi
      done
    fi
    ;;
  delete)
    _KERBEROS

    count=0
    $SAMBATOOL dns delete "${Server}" "${domain}" "${name}" A "${ip}" "$KTYPE"
    result1="$?"
    # get existing reverse zones (if any)
    ReverseZones=$($SAMBATOOL dns zonelist "${Server}" --reverse "$KTYPE" | grep 'pszZoneName' | awk '{print $NF}')
    if [ -z "$ReverseZones" ]
    then
      logger "No reverse zone found, not updating"
      result2='0'
      count=$((count+1))
    else
      for revzone in $ReverseZones
      do
        rev_zone_info "$revzone" "${ip}"
        if [[ ${ip} = $ZoneIP* ]] && [ "$ZoneIP" = "$RZIP" ]
        then
          host -t PTR "${ip}" > /dev/null 2>&1
          ret="$?"
          if [ $ret -eq 0 ]
          then
            $SAMBATOOL dns delete "${Server}" "${revzone}" "${IP2add}" PTR "${name}"."${domain}" "$KTYPE"
            result2="$?"
          else
            result2='0'
            count=$((count+1))
          fi
          break
        else
          continue
        fi
      done
    fi
    result3='0'
    result4='0'
    ;;
*)
    logger "Invalid action specified"
    exit 103
  ;;
esac

result="${result1}:${result2}:${result3}:${result4}"

if [ "$count" -eq 0 ]
then
  if [ "${result}" != "0:0:0:0" ]
  then
    logger "DHCP-DNS $action failed: ${result}"
    exit 1
  else
    logger "DHCP-DNS $action succeeded"
  fi
fi

if [ "$Add_macAddress" != 'no' ]
then
  if [ -n "$DHCID" ]
  then
    Computer_Object=$(ldbsearch "$KTYPE" -H ldap://"$Server" "(&(objectclass=computer)(objectclass=ieee802Device)(cn=$name))" | grep -v '#' | grep -v 'ref:')
    if [ -z "$Computer_Object" ]
    then
      # Computer object not found with the 'ieee802Device' objectclass, does the computer actually exist, it should.
      Computer_Object=$(ldbsearch "$KTYPE" -H ldap://"$Server" "(&(objectclass=computer)(cn=$name))" | grep -v '#' | grep -v 'ref:')
      if [ -z "$Computer_Object" ]
      then
        logger "Computer '$name' not found. Exiting."
        exit 68
      else
        DN=$(echo "$Computer_Object" | grep 'dn:')
        objldif="$DN
changetype: modify
add: objectclass
objectclass: ieee802Device"

        attrldif="$DN
changetype: modify
add: macAddress
macAddress: $DHCID"

        # add the ldif
        echo "$objldif" | ldbmodify "$KTYPE" -H ldap://"$Server"
        ret="$?"
        if [ $ret -ne 0 ]
        then
          logger "Error modifying Computer objectclass $name in AD."
          exit "${ret}"
        fi
        sleep 2
        echo "$attrldif" | ldbmodify "$KTYPE" -H ldap://"$Server"
        ret="$?"
        if [ "$ret" -ne 0 ]; then
          logger "Error modifying Computer attribute $name in AD."
          exit "${ret}"
        fi
        unset objldif
        unset attrldif
        logger "Successfully modified Computer $name in AD"
      fi
  else
    DN=$(echo "$Computer_Object" | grep 'dn:')
    attrldif="$DN
changetype: modify
replace: macAddress
macAddress: $DHCID"

    echo "$attrldif" | ldbmodify "$KTYPE" -H ldap://"$Server"
    ret="$?"
    if [ "$ret" -ne 0 ]
    then
      logger "Error modifying Computer attribute $name in AD."
      exit "${ret}"
    fi
      unset attrldif
      logger "Successfully modified Computer $name in AD"
    fi
  fi
fi

exit 0
EOT
```

##### Шаблон конфигурационного файла без failover
```bash
cat > roles/dhcp_server/templates/dhcpd.conf.j2 <<'EOF'
authoritative;
ddns-update-style none;

subnet {{ network_subnet }} netmask {{ network_netmask }} {
        option broadcast-address        {{ broadcast }};
        option time-offset              0;
        option routers                  {{ network_gateway }};
        option subnet-mask              {{ network_netmask }};

        option nis-domain               "{{ ad_workgroup }}";
        option domain-name              "{{ ad_workgroup }}";
        option domain-name-servers      {{ primary_dc_ip }}, {{ dns_forwarder }};
        option ntp-servers              {{ primary_dc }}.{{ ad_workgroup }};

        pool {
            default-lease-time {{ lease_time }};
            max-lease-time {{ max_lease_time }};
            range {{ dhcp_range }};
        }
}

on commit {
set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
set ClientName = pick-first-value(option host-name, config-option host-name, client-name, noname);
log(concat("Commit: IP: ", ClientIP, " DHCID: ", ClientDHCID, " Name: ", ClientName));
execute("/usr/local/bin/dhcp-dyndns.sh", "add", ClientIP, ClientDHCID, ClientName);
}

on release {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
log(concat("Release: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, ClientDHCID);
}

on expiry {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
log(concat("Expired: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, "", "0");
}
EOF
```

##### Шаблоны конфигурационного файла с участием failover для primary
```bash
cat > roles/dhcp_server/templates/dhcpd_failover_primary.conf.j2 <<'EOF'
authoritative;
ddns-update-style none;

omapi-port 7911;
omapi-key omapi_key;
key "omapi_key" {
        algorithm hmac-md5;
        secret "{{ vault_omapi_secret }}";
};

failover peer "dhcp-failover" {
  primary;
  # Полное DNS-имя основного DHCP-сервера
  address {{ primary_dc }}.{{ ad_workgroup }};
  port 847;
  # Полное DNS-имя имя резервного DHCP-сервера
  peer address {{ secondary_dc }}.{{ ad_workgroup }};
  peer port 647;
  max-response-delay 10;
  max-unacked-updates 5;
  mclt 1800;
  split 255;
  load balance max seconds 2;
}

subnet {{ network_subnet }} netmask {{ network_netmask }} {
        option broadcast-address        {{ broadcast }};
        option time-offset              0;
        option routers                  {{ network_gateway }};
        option subnet-mask              {{ network_netmask }};

        option nis-domain               "{{ ad_workgroup }}";
        option domain-name              "{{ ad_workgroup }}";
        option domain-name-servers      {{ primary_dc_ip }}, {{ secondary_dc_ip }};
        option ntp-servers              {{ primary_dc_ip }}, {{ secondary_dc_ip }};

        pool {
            failover peer "dhcp-failover";
            default-lease-time {{ lease_time }};
            max-lease-time {{ max_lease_time }};
            range {{ dhcp_range }};
        }
}

on commit {
set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
set ClientName = pick-first-value(option host-name, config-option host-name, client-name, noname);
log(concat("Commit: IP: ", ClientIP, " DHCID: ", ClientDHCID, " Name: ", ClientName));
execute("/usr/local/bin/dhcp-dyndns.sh", "add", ClientIP, ClientDHCID, ClientName);
}

on release {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
log(concat("Release: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, ClientDHCID);
}
EOF
```

##### Шаблоны конфигурационного файла с участием failover для secondray
```bash
cat > roles/dhcp_server/templates/dhcpd_failover_second.conf.j2 <<'EOF'
authoritative;
ddns-update-style none;

omapi-port 7911;
omapi-key omapi_key;
key "omapi_key" {
        algorithm hmac-md5;
        secret "{{ vault_omapi_secret }}";
};

failover peer "dhcp-failover" {
  secondary;
  address {{ secondary_dc }}.{{ ad_workgroup }};
  port 647;
  peer address {{ primary_dc }}.{{ ad_workgroup }};
  peer port 847; 
  max-response-delay 10;
  max-unacked-updates 5;
  load balance max seconds 2;
}

subnet {{ network_subnet }} netmask {{ network_netmask }} {
        option broadcast-address        {{ broadcast }};
        option time-offset              0;
        option routers                  {{ network_gateway }};
        option subnet-mask              {{ network_netmask }};

        option nis-domain               "{{ ad_workgroup }}";
        option domain-name              "{{ ad_workgroup }}";
        option domain-name-servers      {{ primary_dc_ip }}, {{ secondary_dc_ip }};
        option ntp-servers              {{ primary_dc_ip }}, {{ secondary_dc_ip }};

        pool {
            failover peer "dhcp-failover";
            default-lease-time {{ lease_time }};
            max-lease-time {{ max_lease_time }};
            range {{ dhcp_range }};
        }
}

on commit {
set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
set ClientName = pick-first-value(option host-name, config-option host-name, client-name, noname);
log(concat("Commit: IP: ", ClientIP, " DHCID: ", ClientDHCID, " Name: ", ClientName));
execute("/usr/local/bin/dhcp-dyndns.sh", "add", ClientIP, ClientDHCID, ClientName);
}

on release {
set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
set ClientDHCID = concat (
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
);
log(concat("Release: IP: ", ClientIP));
execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, ClientDHCID);
}
EOF
```

#### Переменные по умолчанию
```bash
cat > roles/dhcp_server/defaults/main.yml<<'EOF'
---
dhcpduser: dhcpduser
keytab_export_path: "/etc/dhcp/dhcpduser.keytab"
network_subnet: "192.168.100.0"
network_netmask: "255.255.255.0"
network_gateway: "192.168.100.1"
broadcast: "192.168.100.255"
lease_time: "172800"
max_lease_time: "259200"
dhcp_range: "192.168.100.50 192.168.100.254"
...
EOF
```

# gitflic_github репозиторий
```bash
# Добавляем ключи агенту ssh от репозитория gitflic и github
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_gitflic_2026_ed25519 \
&& ssh-add ~/.ssh/id_github_2026_ed25519

git branch -v

git log --oneline

git switch main

git status

pushd \
..

git rm -r --cached \
. ../

git add . ../ \
&& git status

git remote -v

git commit -am "[upd7]ansible" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```