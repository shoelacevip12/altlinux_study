# Лабораторная работа 2 «`Работа с гостевой виртуальной машиной`» 
## Памятка входа
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на хост по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.212 \
"su -"
```
[>>>>>ПОДГОТОВКА ДЛЯ РАБОТЫ с модулем altvirt ADM7<<<<<](../README.md)

![](../0.png)

## Выполнение работы
### Задание 1. Работа с ВМ средствами virt-manager
```bash
exit
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

export LIBVIRT_DEFAULT_URI=qemu+ssh://skvadmin@192.168.89.212/system

virsh uri

virt-manager

ssh \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.212

ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.212 \
"ip -br a"
```

![](img/1.png)
![](img/2.png)
![](img/3.png)
![](img/4.png)
![](img/5.png)
![](img/6.png)
![](img/7.png)
![](img/8.png)

### Задание 2. Работа с ВМ средствами virt-manager
```bash
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.212 \
"su -"

virt-install --name alt-p11-s1 \
--ram 4096 \
--vcpus=2 \
--disk pool=ssd-pool,size=24,bus=virtio,format=qcow2 \
--disk pool=default,size=100,bus=virtio,format=qcow2 \
--cdrom /mnt/isos/alt-server-11.0-x86_64.iso \
--os-type=linux \
--os-variant=alt.p11 \
--graphics vnc \
--network bridge=vmbr0
```

![](img/9.png)
![](img/10.png)
![](img/11.png)

```bash
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519.pub \
skvadmin@192.168.89.208

ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
skvadmin@192.168.89.208 \
"su -"

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
glusterfs11-server

usermod -a -G \
vmusers \
skvadmin

systemctl enable --now \
libvirtd.service

systemctl poweroff
```

![](img/12.png)
![](img/13.png)
![](img/14.png)

```bash
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
skvadmin@192.168.89.212 \
su -

virsh list --all

# Создание snapshot
### Основного сервера сети
virsh snapshot-create-as \
--domain alt-p11-s1 \
--name 1 \
--description "lab2" --atomic

bash -c \
"for i in \$(virsh list --all \
| awk '/alt/ {print \$2}') ; do \
echo "\$i" \
&&virsh snapshot-list \
--domain \$i; done"
```

![](img/15.png)
![](img/16.png)

### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. ../.. \
&& git status

git remote -v

git commit -am 'оформление для ADM7, lab2 base_kvm' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```