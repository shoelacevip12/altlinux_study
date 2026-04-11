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
for r in {base_setup,chrony_sync,samba_ad_dc,dhcp_server,kerberos_client,smb_shares,nfs_server,squid_proxy,sysvol_replication,monitoring_scripts}; do \
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
- Role roles/kerberos_client was created successfully
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

# Сеть
network_subnet: "192.168.100.0"
network_netmask: "255.255.255.0"
network_gateway: "192.168.100.1"
dns_forwarder: "77.88.8.8"
ntp_servers:
  - "192.168.100.12"
  - "192.168.100.13"
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
vault_ad_join_password: "1qaz@WSX"
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
  become: yes
  become_method: su
  become_user: root
  gather_facts: true
  vars:
    # включаем(true)\выключаем(false)
    base_setup: true 
    chrony_sync: false
    samba_ad_dc: false
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

- name: Настройка Kerberos-клиента
  import_playbook: kerberos_client.yaml
  when: kerberos_client | bool

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
  become: yes
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
  become: yes
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
    backup: yes
  notify: Restart chronyd
  when:
  - inventory_hostname == (groups['domain_controllers'] | list)[0]

- name: Настройка chrony.conf для вторичного DC
  template:
    src: chrony.conf.dc_second.j2
    dest: /etc/chrony.conf
    backup: yes
  notify: Restart chronyd
  when:
  - inventory_hostname == (groups['domain_controllers'] | list)[1]

- name: Настройка chrony.conf для пользователей домена
  template:
    src: chrony.conf.members.j2
    dest: /etc/chrony.conf
    backup: yes
  notify: Restart chronyd
  when:
  - inventory_hostname not in groups['domain_controllers']

- name: Запуск и включение службы chronyd
  systemd:
    name: "{{ item }}"
    enabled: yes
    masked: no
    daemon_reload: yes
    enabled: yes
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
    enabled: yes
    masked: no
    daemon_reload: yes
  loop:
    - chronyd
  listen: Restart chronyd
...
EOF
```
```bash
cat > roles/chrony_sync/defaults/main.yml<<'EOF'
---
exter_ntp: ntp3.vniiftri.ru
allow_clients: "192.168.100.0/24"
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

git commit -am "[upd4]ansible" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```