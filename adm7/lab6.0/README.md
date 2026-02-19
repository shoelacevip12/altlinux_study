# «`Подготовка для работы с модулем altvirt ADM7 PROXMOX PVE`»

Установка производилась с образа

[Альт Виртуализация 11](http://ftp.altlinux.org/pub/distributions/ALTLinux/images/p11/virtualization/x86_64/alt-virtualization-pve-11.0-x86_64.iso)

## Установка пакетов и включение модулей
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

ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.208

ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.207

ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.206

ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.200


# чистка списка подключений после libvirt
> ~/.ssh/known_hosts

#запуск агента в текущей сессии терминала
eval $(ssh-agent -s)
# добавление агенту ключ ssh
ssh-add ~/.ssh/id_alt-adm7_2026_host_ed25519

# подключение по ключу и вход под суперпользователем
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
skvadmin@192.168.89.212 \
"su -"

# Установка пакетов
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y \
bridge-utils \
nfs-clients \
nano-icinga2 \
caddy \
fail2ban

# ручной запуск модуля zfs
modprobe zfs

# Проверка подключения
lsmod \
| grep zfs

# установка загрузки модуля в автозагрузку
sed -i 's/#z/z/' \
/etc/modules-load.d/zfs.conf

# Проверка что мостовой интерфейс настроен
brctl show vmbr0
```
## Подключение локального репозитория с образами
![](./img/1.png)
```bash
# Так как при подключении репозитория формируется своя структуру папок то для проброс ISO файлов сформируем ссылку
ln -s \
/mnt/pve/ISO/*.iso \
/mnt/pve/ISO/template/iso/
```
![](./img/2.png)
![](./img/3.png)

```bash
cat /etc/pve/storage.cfg 
```
```
dir: local
        path /var/lib/vz
        content backup,vztmpl,iso

lvmthin: local-lvm
        thinpool data
        vgname pve
        content images,rootdir

nfs: ISO
        export /volume1/iso
        path /mnt/pve/ISO
        server 192.168.89.246
        content iso,vztmpl
        options vers=4.1
        prune-backups keep-all=1
```


## Подготовка к созданию ZFS хранилища
### После перехода с libvirt вычищаем диск в 1.8 ТБ
```bash

lsblk
NAME               MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                  8:0    0   1.8T  0 disk 
|-sda1               8:1    0   300G  0 part 
`-sda2               8:2    0   1.5T  0 part 
sdb                  8:16   0 223.6G  0 disk 
|-sdb1               8:17   0   600M  0 part /boot/efi
`-sdb2               8:18   0   223G  0 part 
  |-pve-root       253:0    0    12G  0 lvm  /
  |-pve-data_tmeta 253:1    0   184M  0 lvm  
  | `-pve-data     253:3    0 180.5G  0 lvm  
  `-pve-data_tdata 253:2    0 180.5G  0 lvm  
    `-pve-data     253:3    0 180.5G  0 lvm
```
### Удаление через fdisk разделов /dev/sdb
```bash
fdisk /dev/sda

Welcome to fdisk (util-linux 2.39.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.


Command (m for help): d
Partition number (1,2, default 2): 

Partition 2 has been deleted.

Command (m for help): d
Selected partition 1
Partition 1 has been deleted.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```
### Просмотр содержимого
```bash
lsblk 
NAME               MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                  8:0    0   1.8T  0 disk 
sdb                  8:16   0 223.6G  0 disk 
|-sdb1               8:17   0   600M  0 part /boot/efi
`-sdb2               8:18   0   223G  0 part 
  |-pve-root       253:0    0    12G  0 lvm  /
  |-pve-data_tmeta 253:1    0   184M  0 lvm  
  | `-pve-data     253:3    0 180.5G  0 lvm  
  `-pve-data_tdata 253:2    0 180.5G  0 lvm  
    `-pve-data     253:3    0 180.5G  0 lvm
```
### вывод об LVM созданного при установке proxmox 
```bash
# вывод о физических томах LVM
pvdisplay

# вывод о логических томах LVM
lvdisplay
```
### Использование Свободных 30 GB для создания под L2ARC-кеш и ZIL-логи для ZFS
```bash
# Создание логического тома в 750 МБ для логов ZFS c именем zfs_log_lv в группе томов pve
lvcreate \
-n zfs_log_lv \
-L 750M \
pve
  Rounding up size to full physical extent 752.00 MiB
  Logical volume "zfs_log_lv" created.

# Создание логического тома на оставшееся дисковое пространство для кеша ZFS c именем zfs_cache_lv в группе томов pve
lvcreate \
-n zfs_cache_lv \
-l 100%FREE \
pve
  Logical volume "zfs_cache_lv" created.
```
### Создание Структуры ZFS

```bash
# Ищем созданные разделы в имени zfs по by-id
ls -lh \
/dev/disk/by-id/ \
| grep zfs
ls: cannot access ''$'\320\277': No such file or directory
lrwxrwxrwx 1 root root 10 Feb 16 22:55 dm-name-pve-zfs_cache_lv -> ../../dm-5
lrwxrwxrwx 1 root root 10 Feb 16 22:53 dm-name-pve-zfs_log_lv -> ../../dm-4

# Ищем свободный диск под zfs по by-id
ls -lh \
/dev/disk/by-id/ \
| grep sda
lrwxrwxrwx 1 root root  9 Feb 16 21:10 ata-ST2000DX002-2DV164_Z4ZBDWY1 -> ../../sda
lrwxrwxrwx 1 root root  9 Feb 16 21:10 scsi-35000c500b24d440e -> ../../sda
lrwxrwxrwx 1 root root  9 Feb 16 21:10 wwn-0x5000c500b24d440e -> ../../sda

# Создаем точку монтирования /srv/zfs0, пул ZFS, L2ARC-кеш и ZIL-логи по идентификаторам
# -f - форсирование создания для перезаписи непустых дисков
# -m - точка монтирования (по умолчанию /pool)
zpool create \
-f -m /srv/zfs0 \
zpool-skv \
ata-ST2000DX002-2DV164_Z4ZBDWY1 \
log \
dm-name-pve-zfs_log_lv \
cache \
dm-name-pve-zfs_cache_lv
```
![](./img/4.png)

#### Создание датасетов

```bash
# Для образов с ОС рабочих машин и контейнеров
zfs create \
zpool-skv/working

# Для дополнительных  образов дисков к рабочим машинам и контейнерам
zfs create \
zpool-skv/storage

# Для клонирования и снэпшоты ZFS
zfs create \
zpool-skv/backup

# Просмотр содержимого
zfs list
NAME                USED  AVAIL  REFER  MOUNTPOINT
zpool-skv           836K  1.76T   104K  /srv/zfs0
zpool-skv/backup     96K  1.76T    96K  /srv/zfs0/backup
zpool-skv/storage    96K  1.76T    96K  /srv/zfs0/storage
zpool-skv/working    96K  1.76T    96K  /srv/zfs0/working
```
![](./img/5.png)

#### Настройка fail2ban Для proxmox
```bash
# Установка пакета 
apt update
apt install fail2ban -y

# создание локального конфигурационного файла
cp /etc/fail2ban/jail.{conf,local}

# указываем список для игнорирования блоков ip
sed -i 's/#ignoreip = 127.0.0.1\/8 ::1/ignoreip = 127.0.0.1\/8 ::1 192.168.89.0\/24/' \
/etc/fail2ban/jail.local

# Добавляем секцию для Proxmox
cat >>/etc/fail2ban/jail.local<<'EOF'
[proxmox]
enabled = true
port = 8006
protocol = tcp
filter = proxmox
logpath = /var/log/pveproxy/access.log
maxretry = 3
bantime = 1h
findtime = 10m
EOF

# Создание фильтра обоснования блокировки на основе логов и их содержимому
cat > /etc/fail2ban/filter.d/proxmox.conf <<'EOF'
[Definition]
failregex = ^<HOST> -.*"POST /access/ticket HTTP/.*" 401
            ^<HOST> -.*"POST /api2/json/access/ticket HTTP/.*" 401
ignoreregex =
EOF

# Включение и запуск Службы
systemctl enable --now \
fail2ban.service
```

### Проверка и тестирование fail2ban
```bash
# Запуск теста по имеющему логу
fail2ban-regex \
/var/log/pveproxy/access.log \
/etc/fail2ban/filter.d/proxmox.conf
```
```
Running tests
=============

Use      filter file : proxmox, basedir: /etc/fail2ban
Use         log file : /var/log/pveproxy/access.log
Use         encoding : UTF-8

 
Results
=======

Failregex: 3 total
|-  #) [# of hits] regular expression
|   2) [3] ^<HOST> -.*"POST /api2/json/access/ticket HTTP/.*" 401
`-

Ignoreregex: 0 total

Date template hits:

Lines: 26204 lines, 0 ignored, 3 matched, 26201 missed
[processed in 6.92 sec]

Missed line(s): too many to print.  Use --print-all-missed to print all 26201 lines
```
```bash
# Вывод статуса активных фильтров для описанных правил
fail2ban-client status
```
```
Status
|- Number of jail:      1
`- Jail list:   proxmox
```
```bash
# Вывод статистики забаненных
fail2ban-client status \
proxmox
```
```
Status for the jail: proxmox
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/pveproxy/access.log
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   31.173.86.93
```
```bash
# Вывод iptables со списком заблокированных
iptables -L
```
```
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
f2b-proxmox  tcp  --  anywhere             anywhere             multiport dports 8006

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain f2b-proxmox (1 references)
target     prot opt source               destination         
REJECT     all  --  31.173.86.93         anywhere             reject-with icmp-port-unreachable
RETURN     all  --  anywhere             anywhere
```
```bash
# Снятие блокировки по ip
fail2ban-client set \
code-server \
unbanip \
31.173.86.93
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

git commit -am "оформление для ADM7 Подготовка Proxmox upd1" \
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
## Развертывание стенда

![](./img/0.png)

### Создание сети для кластера
#### Создаем сетевой мост

![](./img/6.png)

#### ВЫставляем только имя порта на хостовой машине

![](./img/7.png)
![](./img/8.png)

### Создание Виртуальных машин стенда

![](./img/9.png)
![](./img/10.png)
![](./img/11.png)

#### для создания машины с типом UEFI биоса
![](./img/12.png)

![](./img/13.png)
![](./img/14.png)
![](./img/15.png)
![](./img/16.png)
![](./img/17.png)
![](./img/18.png)
![](./img/19.png)
![](./img/20.png)
![](./img/21.png)

#### Установка Altlinux виртуализация 11 платформа PVE
![](./img/22.png)
![](./img/GIF.gif)
![](./img/23.png)
![](./img/24.png)
![](./img/25.png)
![](./img/26.png)


#### Вход на PVE и базовая преднастройка

![](./img/27.png)
![](./img/28.png)
![](./img/29.png)
![](./img/30.png)
![](./img/31.png)
![](./img/32.png)
![](./img/33.png)

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

git commit -am "оформление для ADM7 Подготовка Proxmox upd2" \
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