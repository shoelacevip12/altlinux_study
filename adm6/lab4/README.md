# Лабораторная работа 3 «`Прокси-сервер SQUID`» 
## Памятка входа
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_alt-adm6_2026_host_ed25519

# вход на bastion-хост по ключу по ssh
ssh -t \
-i ~/.ssh/id_alt-adm6_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
sadmin@192.168.121.2 \
"su -"

# Памятка входа на хосты через alt-s-p11-1 по ключу по ssh
## хосты:
### 10.0.0.9 - alt-s-p11-2 - internet
### 10.0.0.8 - alt-s-p11-4 - internet
### 10.20.20.244 - alt-s-p11-3 - DMZ
### 10.1.1.244 - alt-w-p11-1.den.skv - internal
ssh -t \
-i ~/.ssh/id_alt-adm6_2026_host_ed25519 \
-J sadmin@192.168.121.2 \
-o StrictHostKeyChecking=accept-new \
sadmin@ХОСТ \
"su -"

# скриптом поочередно на указанные хосты
for enter in 10.0.0.9 10.0.0.8 10.20.20.244 10.1.1.244; do
ssh -t \
-i ~/.ssh/id_alt-adm6_2026_host_ed25519 \
-J sadmin@192.168.121.2 \
-o StrictHostKeyChecking=accept-new \
sadmin@$enter \
"su -"
done
```

![](../img/0.png)

## Предварительно
### Запуск стенда
```bash
cd adm6/lab4

# Отображение списка snapshot машин стенда
for snap in s{1..4} w1; do \
sudo bash -c \
"virsh snapshot-list adm6_altlinux_$snap"; 
done

# откат прошлых изменений на alt-w-p11-1 в сети s_internal
sudo virsh snapshot-revert \
--snapshotname 2 \
--domain adm6_altlinux_w1

# откат прошлых изменений на alt-s-p11-2 в сети s_internet
sudo virsh snapshot-revert \
--snapshotname 2 \
--domain adm6_altlinux_s2

# откат прошлых изменений на alt-s-p11-1(bastion)
sudo virsh snapshot-revert \
--snapshotname 2 \
--domain adm6_altlinux_s1

# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  \
~/.ssh/id_alt-adm6_2026_host_ed25519

# Поочередный запуск всех сетей libvirt со 2ого по списку
sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-start {}

# запуск ВМ alt-s-p11-route
sudo virsh start \
--domain adm6_altlinux_s1

# Поочередный запуск для лабораторной работы ВМ alt-s-p11-2 - internet и alt-w-p11-1.den.skv - internal
for l1 in w1 s2; do \
sudo bash -c \
"virsh start \
--domain adm6_altlinux_$l1"
done
```
## Выполнение работы
### на узле alt-s-p11-1 (`bastion`)
#### конфигурация nat через nftables 
```bash
# вход на bastion-хост по ключу по ssh
ssh -t \
-i ~/.ssh/id_alt-adm6_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
sadmin@192.168.121.2 \
"su -"

nft flush ruleset

apt-get remove \
nftables -y --purge

apt-get update \
&& apt-get install -y \
nftables

# Создаём необходимую структуру для nftables (семейство, таблица, цепочка) для настройки postrouting NAT:
## где ens5 это интерфейс s_host-libvirt с выходом в реальную WAN сеть 
nft add table ip nat
nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'
nft add rule ip nat postrouting oifname "ens5" counter masquerade
# nft add rule ip nat postrouting ip saddr 10.1.1.240/28 oifname "ens5" counter masquerade
# nft add rule ip nat postrouting ip saddr 10.0.0.0/24 oifname "ens5" counter masquerade
# nft add rule ip nat postrouting ip saddr 10.20.20.240/28 oifname "ens5" counter masquerade

# Включаем и добавляем в автозагрузку службу nftables:
systemctl enable --now \
nftables

# Сохраняем правила nftables
nft list ruleset \
| tee -a /etc/nftables/nftables.nft

systemctl reboot

# Проверка что конфиг применяется
cat /etc/nftables/nftables.nft \
&& systemctl status nftables
```
#### Установка и предварительная настройка squid
```bash
# обновление списка пакетов и установка пакетов для shorewall
apt-get update \
&& apt-get install -y \
squid

# backup конфига
cp -f /etc/squid/squid.conf{,.bak}

# чистка конфига от комментариев
sed -i \
-e '/^[[:space:]]*#/d' \
-e '/^[[:space:]]*$/d' \
/etc/squid/squid.conf

# запуск службы
systemctl enable --now \
squid

systemctl status \
squid
```
#### Своя предварительная настройка squid
##### создаем свои acl списки сетей
```bash
# Добавляем acl локальной сети стенда
sed -i '/deny to_linklocal/a acl s_internal src 10.1.1.240\/28' \
/etc/squid/squid.conf

# Добавляем acl dmz сети стенда
sed -i '/deny to_linklocal/a acl s_dmz src 10.20.20.240\/28' \
/etc/squid/squid.conf

# Добавляем acl имитации сети WAN (s_intenret) сети стенда
sed -i '/deny to_linklocal/a acl s_internet src 10.0.0.0\/24' \
/etc/squid/squid.conf

squid -k reconfigure
```
##### Добавляем к acl спискам правило http_access 
```bash
sed -i '/acl s_internal/a http_access allow s_internal' \
/etc/squid/squid.conf

sed -i '/acl s_internet/a http_access allow s_internet' \
/etc/squid/squid.conf

sed -i '/acl s_dmz/a http_access allow s_dmz' \
/etc/squid/squid.conf

squid -k reconfigure
```
##### настройка режима кеширования
```bash
cat >> /etc/squid/squid.conf <<'EOF'
cache_mem 1024 MB
cache_dir ufs /var/spool/squid 2048 16 256
maximum_object_size 100 MB
maximum_object_size_in_memory 1 MB
EOF

squid -k reconfigure

squid -z
```

![](img/1.png)

##### перенастройка для работы только в сквозном режиме
```bash
## Перенаправление prerouting для squid в прозрачном режиме
### HTTP\https
nft add chain ip nat prerouting '{ type nat hook prerouting priority 0; }'
nft add rule ip nat prerouting iifname "ens6" ip daddr != 10.0.0.254 tcp dport { 80, 443 } counter redirect to :3129
nft add rule ip nat prerouting iifname "ens7" ip daddr != 10.1.1.254 tcp dport { 80, 443 } counter redirect to :3129
nft add rule ip nat prerouting iifname "ens8" ip daddr != 10.20.20.254 tcp dport { 80, 443 } counter redirect to :3129

# Сохраняем правила nftables
nft list ruleset \
| tee -a /etc/nftables/nftables.nft

# Проверка что конфиг применяется
cat /etc/nftables/nftables.nft \
&& systemctl status nftables

# Перенастройка работы squid в только в сквозном режиме
sed -i 's/3128/3129 intercept/' \
/etc/squid/squid.conf

squid -k reconfigure
```

![](img/GIF.gif) ![](img/2.png)

##### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. ../.. \
&& git status

git remote -v

git commit -am 'оформление для ADM6, lab4 squid' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```
#### Настройка правил трафика
```bash
# запуск ВМ alt-s-p11-route
sudo virsh start \
--domain adm6_altlinux_s1

# вход на bastion-хост по ключу по ssh
ssh -t \
-i ~/.ssh/id_alt-adm6_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
sadmin@192.168.121.2 \
"su -"

cat >> /etc/shorewall/rules <<'EOF'
## ssh
SSH(ACCEPT)         s_internal,s_libvirt      all
## http\https
HTTPS(ACCEPT)       s_internal      s_dmz:10.20.20.244
Web(ACCEPT)         s_internal      fw,s_libvirt,s_internet
Web(ACCEPT)         s_internet      fw,s_libvirt
## icmp
Ping(ACCEPT)        s_internal      fw,s_libvirt,s_internet
## dns
DNS(ACCEPT)         s_internal,s_internet   fw,s_libvirt
DNS(ACCEPT)         s_libvirt               fw
### для обновления пакетов хостов в dmz
DNS(ACCEPT)         s_dmz                   fw,s_libvirt
Web(ACCEPT)         s_dmz                   fw,s_libvirt
EOF

# Вывод описания правил
grep -A33 "#ACTION" \
/etc/shorewall/rules
```
#### Настройка правил NAT
```bash
# SNAT из контролируемых зон
cat >> /etc/shorewall/snat <<'EOF'
# ens5 # - 192.168.121.0/24 - "s_host-libvirt" - сеть реального выхода в интернет
# ens6 # - 10.0.0.0/24 - "s_internet" - сеть имитации интернет
# ens7 # - 10.1.1.244 - "s_internal" - сеть локальной сети
# ens8 # - 10.20.20.244 - "s_dmz" - сеть DMZ
# Трансляция nat до реальной сети интернет сетей s_internal и s_dmz
MASQUERADE          ens7        ens5
MASQUERADE          ens8        ens5
# Трансляция nat до имитируемой сети интернет из dmz
MASQUERADE          ens7        ens6
MASQUERADE          ens8        ens6
EOF

# вывод правил snat 
tail \
/etc/shorewall/snat

# Вывод описания правил и DNAT
grep -A36 "#ACTION" \
/etc/shorewall/rules
```

![](img/3.png)

#### Запуск службы shorewall с прописанными правилами и политиками
```bash
# Включаем через конфигурацию постоянное состояние net.ipv4.ip_forward = 1
sed -i '/IP_FORWARDING/s/Keep/On/' \
/etc/shorewall/shorewall.conf

# Включаем разрешение на запуск службы
sed -i '/STARTUP_E/s/No/Yes/' \
/etc/shorewall/shorewall.conf

# Включаем запуск службы
systemctl enable \
--now \
shorewall
```
![](img/GIF.gif)

```bash
# Поочередная остановка запущенных ВМ
for l1 in s{1..4} w1; do \
sudo bash -c \
"virsh destroy --graceful \
--domain adm6_altlinux_$l1"
done
```
##### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. ../.. \
&& git status

git remote -v

git commit -am 'оформление для ADM6, lab4 squid' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```