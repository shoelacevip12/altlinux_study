# Впускная квалификационная работа
# Проектирование и автоматизация внедрения гибридной сетевой инфраструктуры на базе Ansible в составе домена AD, прокси-сервера SQUID и Динамического DNS

![](..//0.vpn/img/0.png)

#### ПАМЯТКА ВХОДА

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
```bash
# Вход на altsrv1 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.254 \
"su -"
```
```bash
# Вход на altsrv2(AD1) по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.253 \
"su -"
```
```bash
# Вход на altsrv3(AD2) по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.252 \
"su -"
```
```bash
# Вход на altsrv4 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.251 \
"su -"
```
```bash
# Вывод у dhcp сервера об аренде ip на примере у хоста altwks2
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.253 \
'su -c \
"grep -B10 altwks2 \
/var/lib/dhcp/dhcpd/state/dhcpd.leases" | grep lease'
```
# `NFS.BASH`

Ранее сервер уже был подготовлен для работы с SAMBA AD

[Развертывание SMB на altsrv4](../4.SMB_server.BASH/README.md) 

## Подготовка Сервера NFS на сервере altsrv4
```bash
# Включаем агента в текущей оснастке и прописываем в базу агента
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn

# Вход на altsrv4 по новому Ip
ssh -t \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.251 \
"su -"

# Устанавливаем пакеты для NFS
apt-get update \
&& apt-get -y install \
rpcbind \
nfs-clients \
nfs-server
```
### Создание параметра работы NFS-сервера в защищенном режиме
```bash
# Создание и присвоение переменной окружения
echo "SECURE_NFS=yes" \
| tee -a /etc/sysconfig/nfs
```
### Настройка экспорта ресурсов NFS
```bash
cat > /etc/exports << 'EOF'
/srv 192.168.100.0/24(rw,no_subtree_check,sec=krb5:krb5i:krb5p,fsid=0)
/srv/smb_work 192.168.100.0/24(rw,no_subtree_check,sec=krb5:krb5i:krb5p)
/srv/smb_NOTadmins 192.168.100.0/24(rw,no_subtree_check,sec=krb5:krb5i:krb5p)
/srv/smb_spec_GR1 192.168.100.0/24(rw,no_subtree_check,sec=krb5:krb5i:krb5p)
/srv/trash 192.168.100.0/24(rw,no_subtree_check,sec=krb5:krb5i:krb5p)
EOF
```
## Настройка аутентификации Kerberos для NFS-сервера
```bash
net ads \
keytab \
add nfs \
-Usmaba_u1
```
```log
Processing principals to add...
Password for [DEN\smaba_u1]:
```
```bash
net ads \
keytab \
list \
| grep nfs
```
```log
  1  AES-256 CTS mode with 96-bit SHA-1 HMAC     nfs/altsrv4.den.skv@DEN.SKV
  1  AES-256 CTS mode with 96-bit SHA-1 HMAC     nfs/ALTSRV4@DEN.SKV
  1  AES-128 CTS mode with 96-bit SHA-1 HMAC     nfs/altsrv4.den.skv@DEN.SKV
  1  AES-128 CTS mode with 96-bit SHA-1 HMAC     nfs/ALTSRV4@DEN.SKV
  1  ArcFour with HMAC/md5                       nfs/altsrv4.den.skv@DEN.SKV
  1  ArcFour with HMAC/md5                       nfs/ALTSRV4@DEN.SKV
```
```bash
# ЗАпуск службы обеспечения связности до kdc сервера домена
systemctl \
enable --now \
rpc-gssd.service 
```
```bash
# проверка правильности и экспорт каталогов
exportfs -vra
```
```log
exporting 192.168.100.0/24:/srv/trash
exporting 192.168.100.0/24:/srv/smb_spec_GR1
exporting 192.168.100.0/24:/srv/smb_NOTadmins
exporting 192.168.100.0/24:/srv/smb_work
exporting 192.168.100.0/24:/srv
```
```bash
systemctl \
enable --now \
nfs-server
```
```log
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /lib/systemd/system/nfs-server.service.
```

## Проверки доступа к сетевым папкам NFS из-под компьютера в домене
```bash
# Включаем агента в текущей оснастке и прописываем в базу агента созданные и переправленные ключи
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_skv_VKR_vpn
```
```bash
# Вход на altwks2 под пользователем с правами 'Domain Admins'
ssh \
-i ~/.ssh/id_skv_VKR_vpn \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
smaba_u1@192.168.100.50
```

<details>
<summary>Лог входа под smaba_u1</summary>

```log
smaba_u1@192.168.100.50's password: 
Last login: Sat Apr  4 22:50:06 2026 from 192.168.100.1
[smaba_u1@altwks2 ~]$
```

</details>

```bash
# Вход под супер пользователем
su -

# Вывод доступных ресурсов NFS
showmount -e \
altsrv4.den.skv
```
```log
Export list for altsrv4.den.skv:
/srv/trash         192.168.100.0/24
/srv/smb_spec_GR1  192.168.100.0/24
/srv/smb_NOTadmins 192.168.100.0/24
/srv/smb_work      192.168.100.0/24
/srv               192.168.100.0/24
```
```bash
# Создание каталогов для монтирования
mkdir -vp /mnt/NFS
```
```bash
mkdir: создан каталог '/mnt/NFS'
```

```bash
mount -t nfs4 altsrv4.den.skv:/ -o rw,sec=krb5:krb5i:krb5p /mnt/NFS/ -vv
```

## Для gitflic и github
```bash
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

git commit -am "[upd1]ДЛЯ ВКР NFS служба" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```