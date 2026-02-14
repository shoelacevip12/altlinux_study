# Лабораторная работа 3 «`Работа с сетевым хранилищем NFS`» 
## Памятка входа
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на реальный хост по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.212 \
"su -"

# вход на на виртуальный KVM-хост по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.208 \
"su -"
```
[>>>>>ПОДГОТОВКА ДЛЯ РАБОТЫ с модулем altvirt ADM7<<<<<](../README.md)

![](img/0.png)

## Выполнение работы
### Настройка NFS-сервера
#### Запуск Виртуального хоста alt-p11-s1
```bash
# Запуск агента
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# Подключение на Физический хост под супер пользователем
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.212 \
"su -"

# Запуск Виртуального хоста
virsh start \
alt-p11-s1
```
### Создание lxc контейнера для libvirt
#### Скачивание файловой системы контейнера и распаковка
```bash
# Создание каталога для файловой системы контейнера
mkdir -p \
/var/lib/lxc/alt-p11-s1/rootfs

# Скачиваем и распаковываем rootfs
curl -o /tmp/alt-rootfs.tar.xz \
https://ftp.altlinux.org/pub/distributions/ALTLinux/images/p11/cloud/x86_64/alt-p11-rootfs-systemd-etcnet-x86_64.tar.xz

tar -xJf \
/tmp/alt-rootfs.tar.xz \
-C /var/lib/lxc/alt-p11-s/rootfs

ll \
/var/lib/lxc/alt-p11-s/rootfs
```
#### Создание пула на Физической Хостовой машине под nfs
```bash
# Список пулов физического хоста
virsh pool-list \
--all \
--details

# создание пула через pool-define-as с автосоданием каталога под NFS
virsh pool-define-as \
for_nfs \
dir - - - - \
"/var/lib/libvirt/images/for_nfs"

# Указание и построение пула как формат "dir"  
virsh pool-build \
for_nfs

# Включение пула для использования
virsh pool-start \
for_nfs

# авто-Включение пула для использования при перезапуске хоста
virsh pool-autostart \
for_nfs
```

![](img/1.png)


```bash
cat > ~/lxc_alt-p11-s2.xml <<'EOF'
<domain type='lxc'>
  <name>lxc_alt-p11-s2</name>
  <memory unit='KiB'>4194304</memory>
  <vcpu>2</vcpu>
  <os>
    <type>exe</type>
    <init>/sbin/init</init>
  </os>
  <devices>
    <filesystem type='mount'>
      <source dir='/var/lib/lxc/alt-p11-s/rootfs'/>
      <target dir='/'/>
    </filesystem>
    <filesystem type='mount'>
      <source dir='/var/lib/libvirt/images/for_nfs'/>
      <target dir='/mnt/nfs-store'/>
    </filesystem>
    <interface type='bridge'>
      <source bridge='vmbr0'/>
    </interface>
    <console type='pty'>
      <target type='lxc' port='0'/>
    </console>
    <tty/>
  </devices>
</domain>
EOF
```
```bash
virsh -c lxc:/// \
undefine \
lxc_alt-p11-s2 2>/dev/null \
|| true

# Создание контейнера через созданный xml конфиг
virsh -c lxc:/// \
define \
~/lxc_alt-p11-s2.xml

# Запуск контейнера
virsh -c lxc:/// \
start lxc_alt-p11-s2

# Подключение к консоли
virsh -c lxc:/// \
console \
lxc_alt-p11-s2
```
![](img/2.png)

### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. ../.. \
&& git status

git remote -v

git commit -am 'оформление для ADM7, lab3 nfs_kvm lxc-run' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```