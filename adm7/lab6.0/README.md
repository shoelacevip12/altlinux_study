# «`Подготовка для работы с модулем altvirt ADM7 PROXMOX PVE`»

Установка производилась с образа

[Альт Виртуализация 11](http://ftp.altlinux.org/pub/distributions/ALTLinux/images/p11/virtualization/x86_64/alt-virtualization-pve-11.0-x86_64.iso)

## Установка пакетов и включение модулей
```bash
su -

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

git commit -am "оформление для ADM7 Подготовка Proxmox" \
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
