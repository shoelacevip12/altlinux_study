# Лабораторная работа 6 «`Развертывание PVE и создание PVE-кластера`» 
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

# вход на виртуальный pve-хост alt-virt11-pve-1 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.208 \
"su -"

# вход на виртуальный pve-хост alt-virt11-pve-2 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.207 \
"su -"

# вход на виртуальный pve-хост alt-virt11-pve-3 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.206 \
"su -"

```
[>>>>>ПОДГОТОВКА ДЛЯ РАБОТЫ с модулем altvirt ADM7<<<<<](../lab6.0/README.md)

![](../lab6.0//img/0.png)

## Выполнение работы
### Со стороны первого узла alt-virt11-pve-1.lab
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm7_2026_host_ed25519

# вход на виртуальный PVE-хост alt-virt11-pve-1 по ключу по ssh и вход под суперпользователя
ssh -t \
-i ~/.ssh/id_alt-adm7_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
skvadmin@192.168.89.208 \
"su -"

# Убираем из myhostname для отработки файла /etc/hosts в 11 платформе
sed -i 's/files myhostname dns/files dns/' \
/etc/nsswitch.conf
```
```
passwd:     files systemd
shadow:     tcb files
group:      files systemd
gshadow:    files


hosts:      files myhostname dns


ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files


automount:  files
aliases:    files
```
```bash
# Производим базовый вывод информации об ip адресации и интерфейсах
ip -br a

# к дополнительному интерфейсу, присваиваем ipv6 адрес
```
```
auto lo
iface lo inet loopback

iface ens19 inet manual

auto ens20
iface ens20 inet6 static
        address fdd2:3918:5fad::1/126

auto vmbr0
iface vmbr0 inet static
        address 192.168.89.208/24
        gateway 192.168.89.1
        bridge-ports ens19
        bridge-stp off
        bridge-fd 0
        dns-nameservers 192.168.89.1
        dns-search lab

source /etc/network/interfaces.d/*
```
![](img/1.png)

```bash
# Изменение локального файла разрешения имен
# себя из-за удаления myhostname в /etc/nsswitch.conf
cat > /etc/hosts <<'EOF'
::1             localhost ip6-localhost ip6-loopback
fdd2:3918:5fad::1 alt-virt11-pve-1.lab alt-virt11-pve-1
fdd2:3918:5fad::2 alt-virt11-pve-2.lab alt-virt11-pve-2
fdd2:3918:5fad::3 alt-virt11-pve-3.lab alt-virt11-pve-3

127.0.0.1       localhost.localdomain localhost
192.168.89.208 alt-virt11-pve-1.lab alt-virt11-pve-1
EOF

ping -c2 \
alt-virt11-pve-2.lab

ping -c2 \
alt-virt11-pve-3.lab
```
#### Формирование уникальной пары ключей для соседних хостов
```bash
# Формирование уникальной пары ключей для соседних хостов
ssh-keygen \
-f ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519 \
-t ed25519 \
-C "fr_pve1_to_pve2"

ssh-keygen \
-f ~/.ssh/id_alt-adm7_pve1-to-pve3_ed25519 \
-t ed25519 \
-C "fr_pve1_to_pve3"

# назначение правильных прав на пары ключей
chmod 600 \
~/.ssh/id_alt-adm7_*_ed25519

chmod 644 \
~/.ssh/id_alt-adm7_*_ed25519.pub
```
#### проброс ключей
##### до узла alt-virt11-pve-2.lab
```bash
# на узел alt-virt11-pve-2.lab сначала до ПОЛЬЗОВАТЕЛЕЙ с правами wheel
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519.pub \
skvadmin@alt-virt11-pve-2.lab

# Вход на пользователя с возможностью перехода в суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519 \
skvadmin@alt-virt11-pve-2.lab \
"su -"

# Перенос проброшенного на пользователя с PVE1 публичного ключа на суперпользователя к подключенному хосту
grep fr_pve1 /home/skvadmin/.ssh/authorized_keys \
>> .ssh/authorized_keys

# проверка наличия
cat .ssh/authorized_keys

# Возращение на PV1
exit
```
```bash
# Проверка Входа на суперпользователя удаленного хоста напрямую
ssh -o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519 \
root@alt-virt11-pve-2.lab

exit
```
##### до узла alt-virt11-pve-2.lab
```bash
# на узел alt-virt11-pve-2.lab сначала до ПОЛЬЗОВАТЕЛЕЙ с правами wheel
ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519.pub \
skvadmin@alt-virt11-pve-2.lab

# Вход на пользователя с возможностью перехода в суперпользователя
ssh -t \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519 \
skvadmin@alt-virt11-pve-2.lab \
"su -"

# Перенос проброшенного на пользователя с PVE1 публичного ключа на суперпользователя к подключенному хосту
grep fr_pve1 /home/skvadmin/.ssh/authorized_keys \
>> .ssh/authorized_keys

# проверка наличия
cat .ssh/authorized_keys

# Возращение на PV1
exit
```
```bash
# Проверка Входа на суперпользователя удаленного хоста напрямую
ssh -o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-adm7_pve1-to-pve2_ed25519 \
root@alt-virt11-pve-2.lab

exit
```

### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. ../.. \
&& git status

git remote -v

git commit -am 'оформление для ADM7, lab6 prox_clus' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```