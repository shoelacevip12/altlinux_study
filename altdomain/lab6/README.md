# Лабораторная работа 6 «`Интеграция служб в Альт Домен`»

![](./img/0.png)

## Памятка входа

```bash
# Регистрация сгенерированного ssh агентом
eval $(ssh-agent) \
&& ssh-add \
~/.ssh/id_alt-domain_2026_host_ed25519

# Хост altwks1
> ~/.ssh/known_hosts \
&& ssh -t -o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"su -"

# Хост dc1
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
"su -"

# Хост dc2
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.12 \
"su -"

# Хост altsrv3 (Nginx)
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
"su -"


# Хост altsrv4 (Samba-server1)
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
"su -"

# Хост altsrv5 (Samba-server2)
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.15 \
"su -"

# Хост altwks2
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.2 \
"su -"
```

## Подготовка для работы

```bash
# Регистрация сгенерированного ssh агентом
eval $(ssh-agent) \
&& ssh-add \
~/.ssh/id_alt-domain_2026_host_ed25519

# Вход на Хост altwks1
> ~/.ssh/known_hosts \
&& ssh -t -o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2

# Проверяем наличие пары ключей ssh на altwks1
find /home/sysadmin/.ssh/ \
| grep alt-domain
```

<details>
<summary>
Проверка наличия пары ssh
</summary>

```log
/home/sysadmin/.ssh/id_alt-domain_2026_host_ed25519.pub
/home/sysadmin/.ssh/id_alt-domain_2026_host_ed25519
```

</details>

### Копирование ssh ключей на узлы

```bash
for ip in 192.168.100.13 192.168.100.14; do
ssh-copy-id \
-i .ssh/id_alt-domain_2026_host_ed25519.pub \
$ip; done
```

<details>
<summary>
Лог копирования ssh ключей на узлы
</summary>

```log
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: ".ssh/id_alt-domain_2026_host_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.13's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '192.168.100.13'"
and check to make sure that only the key(s) you wanted were added.

/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: ".ssh/id_alt-domain_2026_host_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.14's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '192.168.100.14'"
and check to make sure that only the key(s) you wanted were added.
```

</details>

### Вход на сервер Nginx

```bash
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.13 \
"su -"
```

### Отключение IPv6

```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" \
| tee -a  /etc/sysctl.conf \
&& sysctl -p
```

<details>
<summary>
Вывод добавленного содержимого /etc/sysctl.conf
</summary>

```log
net.ipv6.conf.all.disable_ipv6 = 1
```

</details>

```bash
# Вывод о состоянии настроек ядра с IPV6
sysctl -a \
| grep "disable_ipv6"
```

<details>
<summary>
Вывод о состоянии настроек ядра с IPV6
</summary>

```log
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.ens19.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```

</details>

### Смена DNS на интерфейсе и домен поиска

```bash
cat > /etc/net/ifaces/ens19/resolv.conf<<'EOF'
nameserver 192.168.100.11
nameserver 192.168.100.12
search den.skv
EOF
```

### Перезапуск интерфейса и сетевых служб

```bash

ifdown ens19 \
; systemctl restart network \
; ifup ens19
```

### Вывод изменений в resolver

```bash

resolvconf -l
```

<details>
<summary>
вывод resolvconf для обновления системы
</summary>

```log
# resolv.conf from ens19
nameserver 192.168.100.11
nameserver 192.168.100.12
search den.skv
```

</details>

### Смена имени под fqdn

```bash
hostnamectl \
set-hostname \
altsrv3.den.skv
```

### Устанавливаем имя NIS-домена

```bash
domainname den.skv
```

### Обновление системы и Установка пакетов для Web-Nginx

```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get -y install \
nginx \
webserver-common \
nginx-spnego \
qemu-guest-agent \
&& systemctl enable --now qemu-guest-agent
```

### Преднастройка Kerberos

```bash
sed -i "s/# default_realm = EXAMPLE.COM/ default_realm = DEN.SKV/" \
/etc/krb5.conf

sed -i 's/realm = true/realm = false/' \
/etc/krb5.conf

cat /etc/krb5.conf
```

<details>
<summary>
вывод krb5.conf
</summary>

```log
includedir /etc/krb5.conf.d/

[logging]
# default = FILE:/var/log/krb5libs.log
# kdc = FILE:/var/log/krb5kdc.log
# admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_kdc = true
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = DEN.SKV
 default_ccache_name = KEYRING:persistent:%{uid}

[realms]
# EXAMPLE.COM = {
#  default_domain = example.com
# }

[domain_realm]
# .example.com = EXAMPLE.COM
# example.com = EXAMPLE.COM
```

</details>

### Перезагрузка хоста Nginx-web

```bash
systemctl reboot
```

## Выполнение работы на домен контроллере

### Вход на домен контроллер

```bash
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.12 \
"su -"
```

### Получение билета kerberos для администратора

```bash
kinit -V Administrator
```

<details>
<summary>
вывод kinit
</summary>

```log
Using default cache: /tmp/krb5cc_0
Using principal: Administrator@DEN.SKV
Password for Administrator@DEN.SKV: 
Warning: Your password will expire in 27 days on Thu Jul 23 18:39:24 2026
Authenticated to Kerberos v5
```

</details>

### Добавить A-запись для Web-сервера по реальному имени хоста

```bash
samba-tool dns \
add \
dc2.den.skv \
den.skv \
altsrv3 A 192.168.100.13 \
--use-krb5-ccache=/tmp/krb5cc_0
```

### Добавить A-запись для Web-сервера по дополнительному имени хоста

```bash
samba-tool dns \
add \
dc2.den.skv \
den.skv \
web A 192.168.100.13 \
--use-krb5-ccache=/tmp/krb5cc_0
```

### Добавить PTR-запись для Web-сервера дополнительного имени хоста

```bash
samba-tool dns \
add dc2.den.skv \
100.168.192.in-addr.arpa 13 PTR web.den.skv \
--use-krb5-ccache=/tmp/krb5cc_0
```

### SPN и Keytab-файл для Web-сервера

#### Создание пользователя для аутентификации по keytab-файлу

```bash
samba-tool user \
add \
--random-password webauth \
--use-krb5-ccache=/tmp/krb5cc_0

samba-tool user \
setpassword \
webauth \
--random-password

samba-tool user \
setexpiry webauth \
--noexpiry
```

#### Изменение `userPrincipalName:` webauth@`den.skv` на webauth@`DEN.SKV`

```bash
EDITOR=nano samba-tool user edit webauth

Modified User 'webauth' successfully
```

#### Создание SPN на учетную запись и Keytab-файла

```bash
samba-tool spn \
add \
HTTP/web.den.skv \
webauth

samba-tool spn \
add \
HTTP/web.den.skv@DEN.SKV \
webauth

samba-tool domain \
exportkeytab \
/tmp/nginx_web.keytab \
--principal=HTTP/web.den.skv@DEN.SKV
```

### Проверка авторизации по keytab-файлу

```bash
klist -ke /tmp/nginx_web.keytab

kinit -5 -V -k -t /tmp/nginx_web.keytab \
HTTP/web.den.skv@den.skv
```

<details>
<summary>
вывод klist
</summary>

```log
Keytab name: FILE:/tmp/nginx_web.keytab
KVNO Principal
---- --------------------------------------------------------------------------
   4 HTTP/web.den.skv@DEN.SKV (DEPRECATED:arcfour-hmac) 
```

```log
HTTP/web.den.skv@den.skv
Using default cache: /tmp/krb5cc_0
Using principal: HTTP/web.den.skv@den.skv
Using keytab: /tmp/nginx_web.keytab
kinit: Keytab contains no suitable keys for HTTP/web.den.skv@den.skv while getting initial credentials
```

</details>

#### Проброс экспортированного keytab-файла по scp

```bash
scp \
/tmp/nginx_web.keytab \
sysadmin@altsrv3:/tmp/nginx_web.keytab
```

## Выполнение работы на Web-сервере

### Вход на Web-сервер

```bash
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.13 \
"su -"
```

### Включение модуля spnego

```bash
ln -vs /etc/nginx/modules-available.d/http_auth_spnego.conf \
/etc/nginx
/modules-enabled.d/
```

<details>
<summary>
вывод при создании ссылки для включения модуля
</summary>

```log
/modules-enabled.d/
'/etc/nginx/modules-enabled.d/http_auth_spnego.conf' -> '/etc/nginx/modules-available.d/http_auth_spnego.conf'
```

</details>

### Создание nginx конфиг сайта из default.conf

```bash
cp -v /etc/nginx/sites-available.d/{default,web_skv}.conf
```

<details>
<summary>
вывод при создании конфиг сайта
</summary>

```log
'/etc/nginx/sites-available.d/default.conf' -> '/etc/nginx/sites-available.d/web_skv.conf'
```

</details>

### Внесение настроек в конфиг сайта

```bash
sed -i \
's/127.0.0.1/*/' \
/etc/nginx/sites-available.d/web_skv.conf

sed -i \
's/listen  \[/#listen  \[/' \
/etc/nginx/sites-available.d/web_skv.conf

sed -i \
's/localhost localhost.localdomain/web.den.skv/' \
/etc/nginx/sites-available.d/web_skv.conf

sed -i '/root\ \/var\/www\/html;/r /dev/stdin' \
/etc/nginx/sites-available.d/web_skv.conf <<'EOF'
                auth_gss on;
                auth_gss_realm DEN.SKV;
                auth_gss_keytab /etc/nginx/nginx_web.keytab;
                auth_gss_service_name HTTP/web.den.skv;
                auth_gss_allow_basic_fallback off;
                satisfy all;
                error_page 401 /401.html;
                location = /401.html {
                    root /var/www/html;
                    internal;
                }
EOF

cat /etc/nginx/sites-available.d/web_skv.conf
```

<details>
<summary>
вывод настроек после внесения настроек в конфиг сайта
</summary>

```json
#load_module modules/ngx_http_geoip_module.so;
#load_module modules/ngx_http_perl_module.so;
#load_module modules/ngx_mail_module.so;
#load_module modules/ngx_stream_module.so;

server {
        listen  *:80;
        #listen  [::1]:80;
        # can't use wildcards in first server_name
        server_name web.den.skv;

        location / {
            root /var/www/html;
                auth_gss on;
                auth_gss_realm DEN.SKV;
                auth_gss_keytab /etc/nginx/nginx_web.keytab;
                auth_gss_service_name HTTP/web.den.skv;
                auth_gss_allow_basic_fallback off;
                satisfy all;
                error_page 401 /401.html;
                location = /401.html {
                    root /var/www/html;
                    internal;
                }
                # autoindex off;
                # autoindex_exact_size on;
                # autoindex_localtime off;

                # expires off;

                # cooperate with mod_realip in apache-1.3 or mod_rpaf in apache-2.x
                #       proxy_redirect off;
                #       proxy_set_header Host $host;
                #       proxy_set_header X-Real-IP $remote_addr;
                #       proxy_set_header X-Forwarded-For $remote_addr;
                #       proxy_pass http://back.end.addr.ess:80/;
                #
                # NB: it's better for URI canonicalization that apache sits on :80
                # (even if that's only *:80)
                #
                # see also set_real_ip_from, real_ip_header if this nginx
                # would need to cooperate with another one acting as a frontend
        }

#               charset         on;
#               source_charset  koi8-r;

                access_log  /var/log/nginx/access.log;
}
```

</details>

### Создание страницы 401.html для отказа в доступе

```bash
cat > /var/www/html/401.html <<'EOF'
<!DOCTYPE html>
<html>
<head><title>401 Authorization Required</title></head>
<body>
<h1>401 Unauthorized</h1>
<p>Kerberos authentication failed. Access denied.</p>
</body>
</html>
EOF
```

### Создание главно страницы testkrb.html для сайта

```bash
cat > /var/www/html/testkrb.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
</head>
<body>
<h1>
Что-то рабочее с авторизацией по kerberos!
</h1>
</body>
</html>
EOF
```

### Создание символьной ссылки на конфиг nginx `web_skv.conf`

```bash
ln -vs \
/etc/nginx/sites-available.d/web_skv.conf \
/etc/nginx/sites-enabled.d/
```

<details>
<summary>
вывод при создании символьной ссылки на конфиг nginx `web_skv.conf`
</summary>

```log
'/etc/nginx/sites-enabled.d/web_skv.conf' -> '/etc/nginx/sites-available.d/web_skv.conf'
```

</details>

### перенос keytab-файла в директорию `/etc/nginx`

```bash
mv -v /tmp/nginx_web.keytab \
/etc/nginx/
```

<details>
<summary>
вывод при перемещении keytab-файла
</summary>

```log
copied '/tmp/nginx_web.keytab' -> '/etc/nginx/nginx_web.keytab'
removed '/tmp/nginx_web.keytab'
```

</details>

### Проверка конфига nginx на корректность синтаксиса

```bash
nginx -t
```

<details>
<summary>
вывод при проверке конфига
</summary>

```log
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

</details>

### Смена владельца keytab-файла на `_nginx:_nginx`

```bash
chown -v _nginx:_nginx \
/etc/nginx/nginx_web.keytab
```

<details>
<summary>
вывод при смене владельца keytab-файла
</summary>

```log
changed ownership of '/etc/nginx/nginx_web.keytab' from sysadmin:sysadmin to _nginx:_nginx
```

</details>

### Ограничение прав к keytab-файлу (0440)

```bash
chmod -v 0440 \
/etc/nginx/nginx_web.keytab
```

<details>
<summary>
вывод при ограничении прав к keytab-файлу
</summary>

```log
mode of '/etc/nginx/nginx_web.keytab' changed from 0600 (rw-------) to 0440 (r--r-----)
```

</details>

### Запуск nginx

```bash
systemctl enable --now nginx
```

### Тест аутентификации Kerberos для сайта

```bash
curl --negotiate -u : http://web.den.skv/testkrb.html
```

<details>
<summary>
вывод при тесте аутентификации Kerberos
</summary>

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
</head>
<body>
<h1>
Что-то рабочее с авторизацией по kerberos!
</h1>
</body>
</html>
```

</details>

---

![](./img/GIF.gif)
![](./img/2.png)

---

## Настройка SMB-ресурсов на серверах домена

### Ввод altsrv4 в домен

#### Предварительная подготовка

```bash
# Вход под суперпользователем
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
"su -"
```

#### Отключение IPv6 для altsrv4

```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" \
| tee -a  /etc/sysctl.conf \
&& sysctl -p
```

<details>
<summary>
Вывод добавленного содержимого /etc/sysctl.conf
</summary>

```log
net.ipv6.conf.all.disable_ipv6 = 1
```

</details>

#### Вывод о состоянии настроек ядра с IPV6

```bash
sysctl -a \
| grep "disable_ipv6"
```

<details>
<summary>Вывод о состоянии настроек ядра с IPV6</summary>

```log
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.ens19.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```

</details>

#### Смена DNS на интерфейсе и домен поиска узлу altsrv4

```bash
cat > /etc/net/ifaces/ens19/resolv.conf<<'EOF'
nameserver 192.168.100.11
nameserver 192.168.100.12
search den.skv
EOF
```

#### Перезапуск интерфейса и сетевых служб узлу altsrv4

```bash
ifdown ens19 \
; systemctl restart network \
; ifup ens19
```

#### Вывод изменений в resolver узла altsrv4

```bash
resolvconf -l
```

<details>
<summary>вывод resolvconf для обновления системы</summary>

```log
# resolv.conf from ens19
nameserver 192.168.100.11
nameserver 192.168.100.12
search den.skv
```

</details>

#### Обновление системы и установка пакетов

```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get -y install \
samba-common \
samba-client \
task-auth-ad-sssd \
bind-utils \
diag-domain-client \
qemu-guest-agent
```

#### Включение PVE агента

```bash
systemctl enable --now qemu-guest-agent
```

#### Перезагрузка системы

```bash
systemctl reboot
```

#### Ввод в домен altsrv4

```bash
# Вход под суперпользователем
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
"su -"
```

```bash
# Переменные для ввода в домен
host_name="$(hostname -s)"
domain=den.skv
WORKGR=DEN
_REALM=DEN.SKV
_DNS_ADM=Administrator
```

```bash
mkdir -vp /tmp/.private/root/

sed -i "s/# default_realm = EXAMPLE.COM/ default_realm = "$_REALM"/" \
/etc/krb5.conf

sed -i 's/realm = true/realm = false/' \
/etc/krb5.conf

cat /etc/krb5.conf

hostnamectl hostname "$host_name"."$domain" --static

domainname "$domain"

kinit -V "$_DNS_ADM" \
&& system-auth write \
ad \
"$domain" \
"$host_name" \
"$WORKGR" \
&& systemctl reboot
```

<details>
<summary>
Лог входа в домен
</summary>

```log
includedir /etc/krb5.conf.d/

[logging]
# default = FILE:/var/log/krb5libs.log
# kdc = FILE:/var/log/krb5kdc.log
# admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_kdc = true
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = DEN.SKV
 default_ccache_name = KEYRING:persistent:%{uid}

[realms]
# EXAMPLE.COM = {
#  default_domain = example.com
# }

[domain_realm]
# .example.com = EXAMPLE.COM
# example.com = EXAMPLE.COM
Using default cache: persistent:0:0
Using principal: Administrator@DEN.SKV
Password for Administrator@DEN.SKV: 
Warning: Your password will expire in 27 days on Thu Jul 23 18:39:24 2026
Authenticated to Kerberos v5
gensec_gse_client_prepare_ccache: Kinit for ALTSRV4$@den.skv to access ldap/dc1.den.skv failed: Client not found in Kerberos database: NT_STATUS_LOGON_FAILURE
Using short domain name -- DEN
Joined 'ALTSRV4' to dns domain 'den.skv'
Successfully registered hostname with DNS
```

</details>

### Проверка ввода в домен

```bash
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.14 \
"su -"
```

```bash
hostname -f

system-auth status

diag-domain-client
```

<details>
<summary>
Статус проверок
</summary>

```log
altsrv4.den.skv
```

```log
ad DEN.SKV ALTSRV4 DEN
```

```log
[DONE]: Check hostname persistance

[DONE]: Test hostname is FQDN (not short)

[DONE]: System authentication method

[DONE]: Domain system authentication enabled

[DONE]: System policy method

[WARN]: System group policy enabled

[DONE]: Check Kerberos configuration exists

[DONE]: Kerberos credential cache status

[DONE]: Using keyring as kerberos credential cache

[DONE]: Check DNS lookup kerberos KDC status

[DONE]: Check machine crendetial cache is exists

[DONE]: Check machine credentials list in keytab

[DONE]: Check nameserver resolver configuration

[DONE]: Compare krb5 realm and first search domain

[DONE]: Check Samba configuration

[DONE]: Compare samba and krb5 realms

[DONE]: Check Samba domain realm

[DONE]: Check hostname FQDN domainname

[DONE]: Check time synchronization

[DONE]: Time synchronization enabled

[DONE]: Check nameservers availability

[DONE]: Trace Kerberos authentication process

[DONE]: Check domain controllers list

[DONE]: Check Kerberos and LDAP SRV-records

[DONE]: Compare NetBIOS name and hostname

[DONE]: Check common packages

[FAIL]: Check group policy packages

[DONE]: Check SSSD AD packages

[WARN]: Check SSSD Winbind packages
```

</details>

### Создание SMB-ресурсов на серверах

```bash
for ip in 4 5; do \
ssh -t \
-o StrictHostKeyChecking=accept-new \
Administrator@192.168.100.1$ip \
"su - -c \
'mkdir -pv /srv/samba/dfs \
&& chown -vR Administrator:\"Domain Users\" /srv/samba \
&& chmod -vR 2775 /srv/samba \
&& ls -lhd /srv/*'" \
; done
```

<details>
<summary>
лог создания каталогов
</summary>

```log
Warning: Permanently added '192.168.100.14' (ED25519) to the list of known hosts.
Administrator@192.168.100.14's password: 
Password: 
mkdir: created directory '/srv/samba'
mkdir: created directory '/srv/samba/dfs'
changed ownership of '/srv/samba/dfs' from root:root to Administrator:Domain Users
changed ownership of '/srv/samba' from root:root to Administrator:Domain Users
mode of '/srv/samba' changed from 0755 (rwxr-xr-x) to 2775 (rwxrwsr-x)
mode of '/srv/samba/dfs' changed from 0755 (rwxr-xr-x) to 2775 (rwxrwsr-x)
drwxr-xr-x 2 root          root         4.0K Jun  3  2025 /srv/public
drwxrwsr-x 3 administrator domain users 4.0K Jun 26 01:02 /srv/samba
drwxrwxrwt 2 root          root         4.0K Jun  3  2025 /srv/share
Connection to 192.168.100.14 closed.
Warning: Permanently added '192.168.100.15' (ED25519) to the list of known hosts.
Administrator@192.168.100.15's password: 
Password: 
mkdir: created directory '/srv/samba'
mkdir: created directory '/srv/samba/dfs'
changed ownership of '/srv/samba/dfs' from root:root to Administrator:Domain Users
changed ownership of '/srv/samba' from root:root to Administrator:Domain Users
mode of '/srv/samba' changed from 0755 (rwxr-xr-x) to 2775 (rwxrwsr-x)
mode of '/srv/samba/dfs' changed from 0755 (rwxr-xr-x) to 2775 (rwxrwsr-x)
drwxr-xr-x 2 root          root         4.0K Jun  3  2025 /srv/public
drwxrwsr-x 3 administrator domain users 4.0K Jun 26 01:02 /srv/samba
drwxrwxrwt 2 root          root         4.0K Jun  3  2025 /srv/share
Connection to 192.168.100.15 closed.
```

</details>

### Бэкап имеющихся рабочих настроек

```bash
cp -v /etc/samba/smb.conf{,.bak}
```

<details>
<summary>
лог создания каталогов
</summary>

```log
'/etc/samba/smb.conf' -> '/etc/samba/smb.conf.bak'
```

</details>

### чистка конфига от комментариев

```bash
# /^[[:space:]]*#/d - удаляет строки, начинающиеся с #
# /^[[:space:]]*$/d - удаляет пустые строки.
# /^;/d - удаляет строки, начинающиеся с точки с запятой
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
-e '/^;/d' \
/etc/samba/smb.conf
```

### Удаление в `/etc/samba/smb.conf` не используемых ресурсов SMB

```bash
# Где:
# /\[homes\]/ - находит начало удаления
# ,/0775$ - указывает диапазон до строки, закачивающейся 0775
# /d удалить все строки что совпали по диапазону
sed -i '/\[homes\]/,/0775$/d' \
/etc/samba/smb.conf
```

```bash
# Вывод файла /etc/samba/smb.conf
cat !$
```

<details>
<summary>
Конфиг после чистки
</summary>

```ini
cat /etc/samba/smb.conf
[global]
        security = ads
        realm = DEN.SKV
        workgroup = DEN
        netbios name = ALTSRV4
        template shell = /bin/bash
        kerberos method = system keytab
        wins support = no
        winbind use default domain = yes
        winbind enum users = no
        winbind enum groups = no
        template homedir = /home/DEN.SKV/%U
        idmap config * : range = 200000-2000200000
        idmap config * : backend = sss
        machine password timeout = 0
```

</details>

#### Добавление SMB-ресурса в конфигурацию Samba на altsrv4 (Samba-server1)

```bash
cat >/etc/samba/usershares.conf<<'EOF'
[dfs]
        comment = DFS
        path = /srv/samba/dfs
        msdfs root = yes
        writable = yes
        guest ok = no
        read list = +'Domain Users' +'Domain Admins'
        write list = +'Domain Users' +'Domain Admins'
        browseable = yes
        create mask = 2770
        directory mask = 1770
EOF
```

#### Добавляем в Общий конфиг `smb.conf` включение режима dfs

```bash
sed -i '/\[global\]/a\        host msdfs = yes' \
/etc/samba/smb.conf
```

#### Добавляем в Общий конфиг smb.conf обращение к файлу с отдельными прописанными сетевыми ресурсами

```bash
echo "        include = /etc/samba/usershares.conf" \
| tee -a /etc/samba/smb.conf
```

#### Проверка конфигурации Samba

```bash
testparm -s
```

<details>
<summary>
Вывод testparm
</summary>

```log
Load smb config files from /etc/samba/smb.conf
Loaded services file OK.
Weak crypto is allowed by GnuTLS (e.g. NTLM as a compatibility fallback)

SUGGESTION: You may want to use 'sync machine password to keytab' parameter instead of 'kerberos method'.

Server role: ROLE_DOMAIN_MEMBER

# Global parameters
[global]
        kerberos method = system keytab
        machine password timeout = 0
        realm = DEN.SKV
        security = ADS
        template homedir = /home/DEN.SKV/%U
        template shell = /bin/bash
        winbind use default domain = Yes
        workgroup = DEN
        idmap config * : range = 200000-2000200000
        idmap config * : backend = sss
        include = /etc/samba/usershares.conf


[dfs]
        comment = DFS
        create mask = 02770
        directory mask = 01770
        msdfs root = Yes
        path = /srv/samba/dfs
        read list = +'Domain Users' +'Domain Admins'
        read only = No
        write list = +'Domain Users' +'Domain Admins'
```

</details>

#### Вход на altsrv5

```bash
ssh -t \
-o StrictHostKeyChecking=accept-new \
sysadmin@altsrv5 \
"su -"
```

#### Добавление SMB-ресурса в конфигурацию Samba на altsrv5 (Samba-server2)

### Бэкап имеющихся рабочих настроек на altsrv5

```bash
cp -v /etc/samba/smb.conf{,.bak}
```

<details>
<summary>
лог создания каталогов
</summary>

```log
'/etc/samba/smb.conf' -> '/etc/samba/smb.conf.bak'
```

</details>

### чистка конфига от комментариев на altsrv5

```bash
# /^[[:space:]]*#/d - удаляет строки, начинающиеся с #
# /^[[:space:]]*$/d - удаляет пустые строки.
# /^;/d - удаляет строки, начинающиеся с точки с запятой
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
-e '/^;/d' \
/etc/samba/smb.conf
```

### Удаление в `/etc/samba/smb.conf` не используемых ресурсов SMB на altsrv5

```bash
# Где:
# /\[homes\]/ - находит начало удаления
# ,/0775$ - указывает диапазон до строки, закачивающейся 0775
# /d удалить все строки что совпали по диапазону
sed -i '/\[homes\]/,/0775$/d' \
/etc/samba/smb.conf
```

```bash
# Вывод файла /etc/samba/smb.conf
cat !$
```

<details>
<summary>
Конфиг после чистки
</summary>

```ini
cat /etc/samba/smb.conf
[global]
        security = ads
        realm = DEN.SKV
        workgroup = DEN
        netbios name = ALTSRV5
        template shell = /bin/bash
        kerberos method = system keytab
        wins support = no
        winbind use default domain = yes
        winbind enum users = no
        winbind enum groups = no
        template homedir = /home/DEN.SKV/%U
        idmap config * : range = 200000-2000200000
        idmap config * : backend = sss
        machine password timeout = 0
```

</details>

#### Добавление SMB-ресурса в конфигурацию Samba на altsrv5(Samba-server2)

```bash
cat >/etc/samba/usershares.conf<<'EOF'
[dfs]
        comment = DFS
        path = /srv/samba/dfs
        msdfs root = yes
        writable = yes
        guest ok = no
        read list = +'Domain Users' +'Domain Admins'
        write list = +'Domain Users' +'Domain Admins'
        browseable = yes
        create mask = 2770
        directory mask = 1770
EOF
```

#### Добавляем в Общий конфиг `smb.conf` включение режима dfs на altsrv5

```bash
sed -i '/\[global\]/a\        host msdfs = yes' \
/etc/samba/smb.conf
```

#### Добавляем в Общий конфиг smb.conf обращение к файлу с отдельными прописанными сетевыми ресурсами на altsrv5

```bash
echo "        include = /etc/samba/usershares.conf" \
| tee -a /etc/samba/smb.conf
```

#### Проверка конфигурации Samba на altsrv5

```bash
testparm -s
```

<details>
<summary>
Вывод testparm
</summary>

```log
Load smb config files from /etc/samba/smb.conf
Loaded services file OK.
Weak crypto is allowed by GnuTLS (e.g. NTLM as a compatibility fallback)

SUGGESTION: You may want to use 'sync machine password to keytab' parameter instead of 'kerberos method'.

Server role: ROLE_DOMAIN_MEMBER

# Global parameters
[global]
        kerberos method = system keytab
        machine password timeout = 0
        realm = DEN.SKV
        security = ADS
        template homedir = /home/DEN.SKV/%U
        template shell = /bin/bash
        winbind use default domain = Yes
        workgroup = DEN
        idmap config * : range = 200000-2000200000
        idmap config * : backend = sss
        include = /etc/samba/usershares.conf


[dfs]
        comment = DFS
        create mask = 02770
        directory mask = 01770
        msdfs root = Yes
        path = /srv/samba/dfs
        read list = +'Domain Users' +'Domain Admins'
        read only = No
        write list = +'Domain Users' +'Domain Admins'
```

</details>

### Настройка общих ссылок DFS на общие ресурсы в сети

```bash
for ip in 4 5; do \
ssh -t \
-o StrictHostKeyChecking=accept-new \
Administrator@192.168.100.1$ip \
"su - -c \
'pushd /srv/samba/dfs \
&& ln -vs msdfs:altsrv4.den.skv\\\dfs,altsrv5.den.skv\\\dfs linkdfs'" \
; done
```

<details>
<summary>
лог создания ссылок DFS
</summary>

```log
Administrator@192.168.100.14's password: 
Password: 
/srv/samba/dfs ~
'linkdfs' -> 'msdfs:altsrv4.den.skv\dfs,altsrv5.den.skv\dfs'
Connection to 192.168.100.14 closed.
Administrator@192.168.100.15's password: 
Password: 
/srv/samba/dfs ~
'linkdfs' -> 'msdfs:altsrv4.den.skv\dfs,altsrv5.den.skv\dfs'
Connection to 192.168.100.15 closed.
```

</details>

### Запуск службы SMB сервера и службы отображения в сетевом окружении

```bash
for ip in 4 5; do \
ssh -t \
-o StrictHostKeyChecking=accept-new \
Administrator@192.168.100.1$ip \
"su - -c \
'systemctl \
enable --now \
smb \
avahi-daemon \
&& systemctl status smb --no-pager'" \
; done
```

<details>
<summary>
Статус службы smb
</summary>

```log
Administrator@192.168.100.14's password: 
Password: 
Synchronizing state of smb.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable smb
Synchronizing state of avahi-daemon.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable avahi-daemon
● smb.service - Samba SMB Daemon
     Loaded: loaded (/usr/lib/systemd/system/smb.service; enabled; preset: disabled)
     Active: active (running) since Fri 2026-06-26 01:55:46 MSK; 1min 30s ago
 Invocation: 535875b64a6d453f9da26412b9f1d81d
       Docs: man:smbd(8)
             man:samba(7)
             man:smb.conf(5)
   Main PID: 4832 (smbd)
     Status: "smbd: ready to serve connections..."
      Tasks: 3 (limit: 4677)
     Memory: 7.5M (peak: 9.1M)
        CPU: 119ms
     CGroup: /system.slice/smb.service
             ├─4832 /usr/sbin/smbd --foreground --no-process-group
             ├─4835 /usr/sbin/smbd --foreground --no-process-group
             └─4836 /usr/sbin/smbd --foreground --no-process-group

Jun 26 01:55:46 altsrv4.den.skv systemd[1]: Starting smb.service - Samba SMB Daemon...
Jun 26 01:55:46 altsrv4.den.skv systemd[1]: Started smb.service - Samba SMB Daemon.
Connection to 192.168.100.14 closed.
Administrator@192.168.100.15's password: 
Password: 
Synchronizing state of smb.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable smb
Synchronizing state of avahi-daemon.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable avahi-daemon
Created symlink '/etc/systemd/system/multi-user.target.wants/smb.service' → '/usr/lib/systemd/system/smb.service'.
Created symlink '/etc/systemd/system/dbus-org.freedesktop.Avahi.service' → '/usr/lib/systemd/system/avahi-daemon.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/avahi-daemon.service' → '/usr/lib/systemd/system/avahi-daemon.service'.
Created symlink '/etc/systemd/system/sockets.target.wants/avahi-daemon.socket' → '/usr/lib/systemd/system/avahi-daemon.socket'.
● smb.service - Samba SMB Daemon
     Loaded: loaded (/usr/lib/systemd/system/smb.service; enabled; preset: disabled)
     Active: active (running) since Fri 2026-06-26 01:57:26 MSK; 19ms ago
 Invocation: 8b861571bd3443908984e8affe7e827f
       Docs: man:smbd(8)
             man:samba(7)
             man:smb.conf(5)
   Main PID: 4647 (smbd)
     Status: "smbd: ready to serve connections..."
      Tasks: 3 (limit: 4677)
     Memory: 7.2M (peak: 7.5M)
        CPU: 119ms
     CGroup: /system.slice/smb.service
             ├─4647 /usr/sbin/smbd --foreground --no-process-group
             ├─4652 /usr/sbin/smbd --foreground --no-process-group
             └─4653 /usr/sbin/smbd --foreground --no-process-group

Jun 26 01:57:26 altsrv5.den.skv systemd[1]: Starting smb.service - Samba SMB Daemon...
Jun 26 01:57:26 altsrv5.den.skv systemd[1]: Started smb.service - Samba SMB Daemon.
Connection to 192.168.100.15 closed.
```

</details>

```bash
smbclient //altsrv4/dfs \
-k \
-c 'ls'
smbclient //altsrv5/dfs \
-k \
-c 'ls'

smbclient //den.skv/dfs \
-k \
-c 'ls'
```

### Проверка ресурсов серверов smb

```bash
for ip in 4 5; do \
ssh -t \
-o StrictHostKeyChecking=accept-new \
samba_u3@192.168.100.1$ip \
"smbclient -L altsrv4 -k \
&& smbclient -L altsrv5 -k \
&& smbclient -L den.skv -k" \
; done
```

<details>
<summary>
Результаты проверки ресурсов серверов smb
</summary>

```log
samba_u3@192.168.100.14's password: 
WARNING: The option -k|--kerberos is deprecated!

        Sharename       Type      Comment
        ---------       ----      -------
        dfs             Disk      DFS
        IPC$            IPC       IPC Service (Samba 4.21.9-alt3.p11.1)
SMB1 disabled -- no workgroup available
WARNING: The option -k|--kerberos is deprecated!

        Sharename       Type      Comment
        ---------       ----      -------
        dfs             Disk      DFS
        IPC$            IPC       IPC Service (Samba 4.21.9-alt3.p11.1)
SMB1 disabled -- no workgroup available
Connection to 192.168.100.14 closed.
samba_u3@192.168.100.15's password: 
WARNING: The option -k|--kerberos is deprecated!

        Sharename       Type      Comment
        ---------       ----      -------
        dfs             Disk      DFS
        IPC$            IPC       IPC Service (Samba 4.21.9-alt3.p11.1)
SMB1 disabled -- no workgroup available
WARNING: The option -k|--kerberos is deprecated!

        Sharename       Type      Comment
        ---------       ----      -------
        dfs             Disk      DFS
        IPC$            IPC       IPC Service (Samba 4.21.9-alt3.p11.1)
SMB1 disabled -- no workgroup available
Connection to 192.168.100.15 closed.
```

</details>

## Выполнение работы на домен контроллере

### Вход на домен контроллер

```bash
ssh -t \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.12 \
"su -"
```

### Получение билета kerberos для администратора

```bash
kinit -V Administrator
```

<details>
<summary>
вывод kinit
</summary>

```log
Using default cache: /tmp/krb5cc_0
Using principal: Administrator@DEN.SKV
Password for Administrator@DEN.SKV: 
Warning: Your password will expire in 27 days on Thu Jul 23 18:39:24 2026
Authenticated to Kerberos v5
```

</details>

### Добавление SPN под DFS-сервера для домена den.skv

```bash
samba-tool spn add cifs/den.skv altsrv4$

samba-tool spn list altsrv4$
```

<details>
<summary>
вывод samba-tool spn list altsrv4$
</summary>

```log
altsrv4$
User CN=ALTSRV4,CN=Computers,DC=den,DC=skv has the following servicePrincipalName: 
         HOST/ALTSRV4.den.skv
         RestrictedKrbHost/ALTSRV4.den.skv
         HOST/ALTSRV4
         RestrictedKrbHost/ALTSRV4
         cifs/den.skv
```

</details>

## Для github и gitflic

```bash
exit

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

git commit -am "Kerberos_DFS" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main \
&& git push \
--set-upstream \
altlinux_sc \
main

popd
```
