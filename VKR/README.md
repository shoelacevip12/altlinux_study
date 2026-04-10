# Впускная квалификационная работа
# `Проектирование и автоматизация внедрения гибридной сетевой инфраструктуры на базе Ansible в составе домена AD, прокси-сервера SQUID и Динамического DNS`

![](0.vpn/img/0.png)

# Ход выполнения Автоматизации
## Предварительные действия перед выполнением (Доступ до закрытого контура через Openvpn)
### Развертывание сервера Сертификации на сервере Openvpn
#### Установка пакетов на сервере Openvpn
```bash
# Поиск пакетов
sudo pacman \
-Ss \
openvpn

sudo pacman \
-Ss \
easyrsa

# Установка пакетов
sudo pacman \
-Syu \
easy-rsa \
openvpn
```
#### Генерация пар сертификатов\ключей для TLS VPN
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
shoellin \
nopass

# сертификат\ключ VPN-клиента
easyrsa build-client-full \
altwks1 \
nopass
```
```bash
# Перенос в каталог для облачного хранилища генерации Диффи-Хелмана и пары сертификата\ключа для VPN-сервера
sudo cp \
/srv/pki/{ca.crt,dh.pem} \
/srv/pki/issued/altwks1.crt \
/srv/pki/private/altwks1.key \
~/nfs_git/
```
### Подготовка VPN-клиента
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

# Копируем сгенерированный HMAC в домашний каталог для обмена через файловое облако между VPN-сервер\клиентом
cp /etc/openvpn/keys/ta.key \
/home/sysadmin/

# взаимодействовать с файлом на уровне пользователя
chown sysadmin:sysadmin \
/home/sysadmin/ta.key
```
#### После обмена файлами ключей в домашней каталог
```bash
# Копирование всех необходимых файлов
cp /home/sysadmin/{ca.crt,altwks1.*,ta.key} \
/etc/openvpn/keys/

# Выставление желательных прав для ключей\сертификатов
chmod -R 600 /etc/openvpn/keys
```
```bash
# Создание конфига туннельного соединения-клиента по subnet топологии
cat > /etc/openvpn/client/tun0.conf <<'EOF'
dev tun0
  client
  nobind
  remote 46.148.105.24 1194
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
# Добавляем в hosts ip и имя внешнего сервера VPN 
# имя указанного хоста соответствует на чье имя был выписан сертификат из CA (openvpn-altserver)
echo -e "\n185.215.60.87 shoellin" \
>> /etc/hosts

# Включение и запуск службы VPN-клиента
systemctl enable \
--now \
openvpn-client@tun0
```
#### Подготовка службы сервера openVPN
```bash
# Создание каталога для пары ключей и сертификатов
sudo mkdir \
/etc/openvpn/keys/

# Копирование подготовленных файлов пары ключей и сертификатов для сервера
sudo cp pki/{issued,private}/shoellin.* \
/srv/pki/{ca.crt,dh.pem} \
/etc/openvpn/keys/

# Копирование Ключа HMAC созданного с VPN-клиента
sudo cp ~/nfs_git/ta.key \
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
  local 192.168.89.193
  port 1194
  proto udp4
  keepalive 10 60
  topology subnet
  server 172.16.100.0 255.255.255.248
  data-ciphers-fallback AES-256-CBC
  cipher AES-256-CBC
  ca /etc/openvpn/keys/ca.crt
  dh /etc/openvpn/keys/dh.pem
  cert /etc/openvpn/keys/shoellin.crt
  key /etc/openvpn/keys/shoellin.key
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
# генерация пары ssh ключей для подключения к стенду ВКР
ssh-keygen -f \
~/.ssh/id_skv_VKR_vpn \
-t ed25519 -C "VKR_vpn"

# проброс ключа до altwks1 через Openvpn
> ~/.ssh/known_hosts \
&& ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_skv_VKR_vpn.pub \
sysadmin@172.16.100.2
```


```
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/shoel/.ssh/id_skv_VKR_vpn.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
Number of key(s) added: 1

Now try logging into the machine, with: "ssh -i /home/shoel/.ssh/id_skv_VKR_vpn -o 'StrictHostKeyChecking=accept-new' 'sysadmin@172.16.100.2'"
and check to make sure that only the key(s) you wanted were added.
```

```bash
# Включаем агента в текущей оснастке и прописываем в базу агента созданные и переправленные ключи
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn
```
```bash
# вход на bastion хост по ключу по ssh
> ~/.ssh/known_hosts \
&& ssh -t -o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"su -"
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

# создание каталога inventory для хостов
mkdir -p inventory/{group_vars,host_vars}

mkdir -p inventory/group_vars/all

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
# Общие параметры домена
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
  - "192.168.100.253"
  - "192.168.100.252"
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
./inventory/group_vars/all/vault.yml
```


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

git commit -am "[upd0]ansible" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```