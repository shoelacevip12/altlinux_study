# Лабораторная работа 3 «`Межсетевой экран(shorewall)`» 
## Памятка входа
```bash
# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm6_2026_host_ed25519

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
cd adm6/lab3

# Отображение списка snapshot машин стенда
for snap in s{1..4} w1; do \
sudo bash -c \
"virsh snapshot-list adm6_altlinux_$snap"; 
done 

# откат прошлых изменений на alt-w-p11-1
sudo virsh snapshot-revert \
--snapshotname 2 \
--domain adm6_altlinux_w1

# Включаем агента в текущей оснастке
> ~/.ssh/known_hosts
eval $(ssh-agent) \
&& ssh-add  ~/.ssh/id_alt-adm6_2026_host_ed25519

# Поочередный запуск всех сетей libvirt со 2ого по списку
sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-start {}

# запуск ВМ alt-s-p11-route
sudo virsh start \
--domain adm6_altlinux_s1

# Поочередный запуск для лабораторной работы ВМ alt-s-p11-2 - internet и alt-w-p11-1.den.skv - internal
for l1 in s2 w1; do \
sudo bash -c \
"virsh start \
--domain adm6_altlinux_$l1"
done
```
## Выполнение работы
### на узле alt-s-p11-1 (`bastion`)
#### чистка конфигурации nftables
```bash
# вход на bastion-хост по ключу по ssh
ssh -t \
-i ~/.ssh/id_alt-adm6_2026_host_ed25519 \
-o StrictHostKeyChecking=accept-new \
sadmin@192.168.121.2 \
"su -"

# чистка ранее развернутого nftables в режиме nat для всех внутренних сетей стенда
nft flush ruleset \
&& nft list ruleset

# Выключаем и исключаем из автозагрузки службу nftables:
systemctl disable --now \
nftables

# Перезапуск службы сети
systemctl restart network
```
#### Установка и предварительная установка shorewall
```bash
# обновление списка пакетов и установка пакетов для shorewall
apt-get update \
&& apt-get install -y \
shorewall

# Проверка состояния net.ipv4.ip_forward = 1
grep "rd = " \
/etc/net/sysctl.conf 
```
#### Описание зон сетей
```bash
# Описание зоны реального выхода в интернет
echo "s_host-libvirt        ip" \
>> /etc/shorewall/zones

# Описание зоны имитации интернет
echo "s_internet        ip" \
>> /etc/shorewall/zones

# Описание локальной сети
echo "s_internal       ip" \
>> /etc/shorewall/zones

# Описание сети DMZ
echo "s_dmz       ip" \
>> /etc/shorewall/zones

# Вывод описания зон
grep -A6 "ZONE" /etc/shorewall/zones
```
#### Привязка зон к интерфейсам
```bash
# где:
# ens5 # - 192.168.121.0/24 - "s_host-libvirt" - сеть реального выхода в интернет
# ens6 # - 10.0.0.0/24 - "s_internet" - сеть имитации интернет
# ens7 # - 10.1.1.244 - "s_internal" - сеть локальной сети
# ens8 # - 10.20.20.244 - "s_dmz" - сеть DMZ
cat >> /etc/shorewall/interfaces <<'EOF'
-               lo            ignore
s_host-libvirt  ens5
s_internet      ens6
s_internal      ens7
s_dmz           ens8
EOF

# Вывод описания зон
grep -A6 "ZONE" /etc/shorewall/zones

# Вывод описания привязки зон к интерфейсам
grep -A6 "ZONE" /etc/shorewall/interfaces
```
![](img/1.png)
#### Описание политик хождения трафика относительно зон и самого shorewall
```bash
cat >> /etc/shorewall/policy <<'EOF'
# Разрешение shorewall взаимодействовать со всеми сетями
$FW             all         ACCEPT
# Блокировать c ответом соединение из локальной сети ко всеми сетями
s_internal      all         REJECT      $LOG_LEVEL
# Блокировать c ответом соединение из сети dmz ко всеми сетями
s_dmz           all         REJECT      $LOG_LEVEL
# Блокировать соединение из реального WAN со всеми сетями
s_host-libvirt  all         DROP        $LOG_LEVEL
# Блокировать соединение из имитирующего WAN со всеми сетями
s_internet      all         DROP        $LOG_LEVEL
# Массовое блокирование всего, что не разрешено
all             all         DROP        $LOG_LEVEL
EOF

# Вывод описания политик по умолчанию
tail -n13 \
/etc/shorewall/policy
```
![](img/2.png)
## Промежуточное сохранение(snapshot) машины
```bash
# выключение машины
systemctl poweroff

# вывод списка snapshot хоста
sudo virsh snapshot-list \
adm6_altlinux_s1

# Создание snapshot
### Основного сервера сети
sudo virsh snapshot-create-as \
--domain adm6_altlinux_s1 \
--name 3 \
--description "shorewall_policy" --atomic
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

git commit -am 'оформление для ADM6, lab3 shorewall Upd_2' \
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
```
```bash
# Поочередная остановка запущенных ВМ
for l1 in s{1,2} w1; do \
sudo bash -c \
"virsh destroy --graceful \
--domain adm6_altlinux_$l1"
done
```