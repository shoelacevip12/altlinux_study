# «`Подготовка для работы с модулем altvirt ADM7`»

## Предварительно 
### Установка пакетов и запуск службы Libvirt
```bash
su -

apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y  \
libvirt \
libvirt-daemon \
libvirt-kvm \
libvirt-qemu \
qemu-kvm \
libvirt-lxc \
virt-install \
libvirt-daemon-driver-storage-logical \
nfs-server \
rpcbind \
bridge-utils \
nfs-clients \
nfs-server \
glusterfs11-server \
git \
timeshift \
glibc \
libstdc++6 \
nano-icinga2 \
caddy \
fail2ban

usermod -a -G \
vmusers \
skvadmin

systemctl enable --now \
libvirtd.service
```
### Установка мостового интерфейса для физического хоста
```bash
cp -r \
/etc/net/ifaces/{enp59s0,vmbr0}

sed -i 's/eth/bri/' \
/etc/net/ifaces/vmbr0/options

sed -i '/bri/aHOST=enp59s0' \
/etc/net/ifaces/vmbr0/options

sed -i "s/dhcp/static/" \
/etc/net/ifaces/enp59s0/options

sed -i "s/static4/static/" \
/etc/net/ifaces/enp59s0/options

systemctl restart network

mkdir \
/mnt/isos

chmod +s \
/mnt/isos

echo '192.168.89.246:/volume1/iso /mnt/isos nfs rw,soft,intr,noatime,nodev,nosuid 0 0' \
>>/etc/fstab

mount -a
```
![](./0.png)
```bash
cat /etc/net/ifaces/enp59s0/*

BOOTPROTO=static
TYPE=eth
SYSTEMD_CONTROLLED=no
DISABLED=no
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=yes
NM_CONTROLLED=no
ONBOOT=yes
```
```bash
cat /etc/net/ifaces/vmbr0/*

BOOTPROTO=dhcp
TYPE=bri
HOST=enp59s0
SYSTEMD_CONTROLLED=no
DISABLED=no
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
NM_CONTROLLED=no
ONBOOT=yes
```
### Установка и настройка code-server
```bash
wget \
https://github.com/coder/code-server/releases/download/v4.108.2/code-server-4.108.2-amd64.rpm

apt-get install \
./code-server-4.108.2-amd64.rpm

cat >/usr/lib/systemd/system/code-server@.service<<'EOF'
[Unit]
Description=code-server
After=network.target

[Service]
Type=exec
ExecStart=/usr/bin/code-server
StandardOutput=append:/var/log/code-server.log
StandardError=append:/var/log/code-server.log
Restart=always
User=%i

[Install]
WantedBy=default.target
EOF

touch /var/log/code-server.log

chmod 644 \
/var/log/code-server.log 

systemctl daemon-reload

systemctl enable --now \
code-server@skvadmin
```

### Настройка timeshift
```bash
timeshift --list

lsblk /dev/sda1

blkid /dev/sda1

cp /etc/timeshift/timeshift.json{,.bak}

cat > /etc/timeshift/timeshift.json <<'EOF'
{
  "backup_device_uuid" : "61eabc6e-af1a-436c-b76c-b870ce4da7a4",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "false",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "true",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "4831012258",
  "snapshot_count" : "95460",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
    "/home/skvadmin/**",
    "/root/**",
  ],
  "exclude-apps" : []
EOF

timeshift --list

timeshift --check
```
### code-server caddy fail2ban
#### настройка caddy
```bash
usermod -aG \
skvadmin \
fail2ban

cp  /etc/caddy/Caddyfile{,.bak}

> /etc/caddy/Caddyfile

cat >/etc/caddy/Caddyfile<<'EOF'
shoel.myds.me/skvadmin/* {
  log {
        output file /var/log/caddy/access.log {
                roll_size 1gb
                roll_keep 5
                roll_keep_for 720h
        }
}
  uri strip_prefix /skvadmin
  reverse_proxy 127.0.0.1:8081
}
EOF

mkdir /var/log/caddy

touch /var/log/caddy/access.log

chown _caddy:_webserver \
/var/log/caddy/access.log

systemctl enable --now \
caddy
```
#### Настройка fail2ban Для caddy
```bash
cat >/etc/fail2ban/filter.d/caddy-status.conf<<'EOF'
[Definition]
failregex = ^.*"remote_ip":"<HOST>",.*?"status":(?:401|403|500),.*$
ignoreregex =
datepattern = LongEpoch
EOF

cat >/etc/fail2ban/jail.local<<'EOF'
[caddy-status]
enabled     = true
port        = http,https
filter      = caddy-status
logpath     = /var/log/caddy/access.log
maxretry    = 10
EOF
```
#### Настройка fail2ban Для code-server
```bash
cat >/etc/fail2ban/filter.d/code-server.conf<<'EOF'
[Definition]
# Извлекаем IP из xForwardedFor (приоритет) или remoteAddress
failregex = ^Failed login attempt \{.*"xForwardedFor":"<ADDR>".*\}$
            ^Failed login attempt \{.*"remoteAddress":"<ADDR>".*\}$

# Дополнительные шаблоны для совместимости с разными версиями code-server
# failregex = ^.*\[.*\] Failed to authenticate.*from <ADDR>.*$
# failregex = ^.*Authentication failed for.*<ADDR>.*$

# Игнорируем успешные подключения и системные сообщения
ignoreregex =

# Явно указываем формат даты
datepattern = {^LN-BEG}%%Y-%%m-%%dT%%H:%%M:%%S\.%%fZ
EOF

cat >/etc/fail2ban/jail.d/code-server.local<<'EOF'
[code-server]
enabled  = true
port     = http,https  # КРИТИЧЕСКИ ВАЖНО: банить 80/443, а не 8080/8081!
logpath  = /var/log/code-server.log
maxretry = 3
findtime = 600
bantime  = 3600
filter   = code-server
action   = iptables-multiport[name=code-server, port="http,https", protocol=tcp]
EOF

systemctl enable --now \
fail2ban.service
```
### Проверка и тестирование fail2ban
```bash
fail2ban-regex \
/var/log/code-server.log \
/etc/fail2ban/filter.d/code-server.conf

echo 'Failed login attempt \
{"xForwardedFor":"192.168.1.100","remoteAddress":"127.0.0.1","userAgent":"test","timestamp":1234567890}' \
| tee -a /var/log/code-server.log

fail2ban-client status

fail2ban-client status code-server

fail2ban-client status caddy-status

iptables -L

fail2ban-client set \
code-server \
unbanip \
185.234.247.121
```
### Для github и gitflic
```bash
cd ~/altlinux/adm

git init

git config --global \
user.email \
"shoelacevip21@gmail.com"

git config --global \
user.name \
"shoelacevip12"

git config --global \
--add safe.directory .

git remote add \
altlinux \
https://github.com/shoelacevip12/altlinux_study.git

git remote add \
altlinux_gf \
https://gitflic.ru/project/shoelacevip12/altlinux_study.git

git log \
--oneline

git pull \
altlinux main
```

### Подготовка структуры прохождения курса alt adm7 altvirt
```bash
mkdir amd7

cd !$

mkdir -p lab{1..9}/img
```

```bash
su -

# вывод всех доступных сетей
virsh net-list \
--all
```

```bash
# экспорт настроек созданных сетей libvirt
virsh net-dumpxml \
default \
> ./mngt_net.xml

mv ./mngt_net.xml \
/home/skvadmin/

chown skvadmin:skvadmin \
/home/skvadmin/mngt_net.xml
```
```xml
<network>
  <name>default</name>
  <uuid>148551aa-8f46-4e8d-a2e8-0321c7e7d2e1</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:30:9e:20'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

### Для github и gitflic
```bash
exit

git branch -v

git log --oneline

git switch main

git status

pushd \
../..

git rm -r --cached \
. 

git add . \
&& git status

git remote -v

git commit -am "оформление для ADM7 Подготовка upd3" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main

popd
```

## Рекомендации: WSL2 + Ubuntu (Windows 10)

### Шаг 1: Включите WSL2 и установите Ubuntu

```powershell
# Откройте PowerShell от имени администратора и выполните:
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

1. Перезагрузите компьютер
2. Скачайте и установите [пакет ядра WSL2](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)
3. Установите дистрибутив из Microsoft Store:
   - Откройте **Microsoft Store** → найдите **"Ubuntu 22.04 LTS"** → установите
4. Запустите Ubuntu из меню "Пуск", создайте пользователя и пароль

### Шаг 2: Настройте WSL2 для работы с GUI-приложениями

Для отображения графического интерфейса `virt-manager` потребуется X-сервер для Windows:

1. Скачайте и установите **VcXsrv** (рекомендуется) или **Xming**:
   - https://sourceforge.net/projects/vcxsrv/
2. Запустите **XLaunch**:
   - Multiple windows → Display number: 0
   - Start no client
   - Отключите "Native opengl" (галочка снята)
   - Включите "Disable access control" (галочка установлена) ← **важно!**
   - Сохраните конфигурацию на рабочий стол

### Шаг 3: Установите virt-manager в Ubuntu/WSL2

```bash
# Обновите систему
sudo apt update \
&& sudo apt upgrade -y

# Установите virt-manager и зависимости
sudo apt install -y \
virt-manager \
libvirt-clients \
qemu-kvm \
ssh-askpass-gnome

# Настройте переменные окружения для X11 (добавьте в ~/.bashrc)
echo 'export DISPLAY=127.0.0.1:0' >> ~/.bashrc
echo 'export LIBGL_ALWAYS_INDIRECT=1' >> ~/.bashrc
source ~/.bashrc
```

### Шаг 4: Настройте подключение к удаленному libvirt-серверу

1. **Создайте SSH-ключ** (если еще нет):
   ```bash
   ssh-keygen \
   -f ~/.ssh/id_alt-adm7_2026_host_ed25519 \
   -t ed25519 \
   -C "cours_alt-adm7"

   chmod 600 \
   ~/.ssh/id_alt-adm7_2026_*_ed25519
   
   chmod 644 \
   ~/.ssh/id_alt-adm7_2026_*_ed25519.pub

   ssh-copy-id \
   -o StrictHostKeyChecking=accept-new \
   -i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
   skvadmin@192.168.89.212
   ```

2. **Проверьте подключение по SSH**:
   ```bash
   > ~/.ssh/known_hosts

   eval $(ssh-agent -s)

   ssh-add ~/.ssh/id_alt-adm7_2026_host_ed25519

   ssh -i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
   skvadmin@192.168.89.212
   # Должен входить без пароля
   ```

3. **Запустите virt-manager**:
   ```bash
   virt-manager
   ```

4. **Добавьте удаленное подключение**:
   - File → Add Connection
   - Hypervisor: **QEMU/KVM**
   - Method: **SSH**
   - Username: ваш пользователь на сервере
   - Hostname: IP или домен удаленного сервера
   - Нажмите **Connect**

URI подключения будет выглядеть так:
```
qemu+ssh://skvadmin@192.168.89.212/system
```
![](./adm7.png)