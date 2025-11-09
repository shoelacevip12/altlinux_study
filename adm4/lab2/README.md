# Лабораторная работа 2 «`Настройка DNS-сервера в ОС Альт`» `Скворцов Денис`
#### памятка для входа на машины локальной сети
```bash
# включаем агента и запущенному процессу регистрируем используемые ключи
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_vm \
&& ssh-add  ~/.ssh/id_kvm_host_to_vms

# Шлюз
ssh \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route

# Основной сервер локальной сети
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@alt-w-p11-route" \
-i ~/.ssh/id_vm sadmin@alt-s-p11-1

# сервер alt-s-p11-2
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@192.168.121.2" \
-i ~/.ssh/id_vm sadmin@10.10.10.242

# сервер alt-s-p11-3
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@192.168.121.2" \
-i ~/.ssh/id_vm sadmin@10.10.10.243

# сервер alt-w-p11-1
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@192.168.121.2" \
-i ~/.ssh/id_vm sadmin@10.10.10.244
```
### Предварительно
##### Для github
```bash
cd ~/altlinux/adm/adm4

git branch -v

git remote -v


git remote add altlinux https://github.com/shoelacevip12/altlinux_study.git

git log --oneline

git pull altlinux main
```
### Подготовка и Запуск стенда
```bash
# включаем агента-ssh
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_vm \
&& ssh-add  ~/.ssh/id_kvm_host_to_vms

mkdir -p lab2/img

cd lab2

touch README.md

# Поочередный запуск всех сетей libvirt со 2ого по списку
sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-start {}

# Создание snapshot
### Основного сервера сети
sudo virsh snapshot-create-as \
--domain adm4_altlinux_s1 \
--name 2 \
--description "before_lab2" --atomic

### Вторичного сервера сети
sudo virsh snapshot-create-as \
--domain adm4_altlinux_s2 \
--name 2 \
--description "before_lab2" --atomic

#### Основного шлюза сети
sudo virsh snapshot-create-as \
--domain adm4_altlinux_w2 \
--name 2 \
--description "before_lab2" --atomic

# Поочередный запуск всех ВМ содержащих "nux"
sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$2}') ; do \
virsh start --domain \$i; done"
```
#### Проверка работы DHCP с прошлой лабораторной работы
```bash
# Подключение к основному серверу локальной сети
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@alt-w-p11-route" \
-i ~/.ssh/id_vm sadmin@alt-s-p11-1

su -

# Проверка работы DHCP
journalctl -feu dhcpd

# для формирования arp таблицы на интерфейсе
for c in {2..4}; do
ping -c 1 10.10.10.24$c; done

# проверка получившейся связности связности между узлами локальной сети
ip nei

exit

exit
```
![](img/1.png)![](img/2.png)
#### Проброс ключей с хостовой машины на оставшиеся ВМ
```bash
ssh-copy-id \
-i ~/.ssh/id_vm.pub \
-o "ProxyJump sadmin@192.168.121.2" \
sadmin@10.10.10.242

ssh-copy-id \
-i ~/.ssh/id_vm.pub \
-o "ProxyJump sadmin@192.168.121.2" \
sadmin@10.10.10.243

ssh-copy-id \
-i ~/.ssh/id_vm.pub \
-o "ProxyJump sadmin@192.168.121.2" \
sadmin@10.10.10.244
```
## План для выполнения 
![](img/0.png)

### Выполнение работы
#### установка bind на шлюзе, alt-s-p11-1 и alt-s-p11-2
```bash
cd ../ansible-automation/

ansible-playbook role_bind.yaml

cd -
```
![](img/3.gif)
#### Настройка службы BIND на кэширование на шлюзе сети и forward на зону den.skv.
```bash
# Шлюз
ssh \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route

su -

systemctl stop bind

cd /var/lib/bind

# даем доступ на dump кеша согласно пути по умолчанию в ./etc/options.conf
chmod g+x var 

# Прослушивать только локальный порт и Loopback интерфейс
sed -i 's/0.1;/0.1; 10.10.10.240\/28;/' etc/options.conf

# Указываем на работу только на IPv4
sed -i 's/S=""/S="-4"/' /etc/sysconfig/bind

# Ограничиваем рекурсию запросов
sed -i 's|//allow-recursion { localnets|allow-recursion { 10.10.10.240/28|' \
etc/options.conf
```
##### тестовый запуск
```bash
systemctl start bind

host ya.ru 10.10.10.254

host mail.ru 127.0.0.1

systemctl stop bind
```
![](img/4.png)
#### Настраиваем Forward запросов на наш домен на наши сервера
```bash
# Зону прямого просмотра 
cat >>./etc/local.conf<<'EOF'
zone "den.skv" {
    type forward;
    forward only;
    forwarders { 10.10.10.242; 10.10.10.241; };
};
EOF

# Зону обратного просмотра 
cat >>./etc/local.conf<<'EOF'
zone "10.10.10.in-addr.arpa" {
    type forward;
    forward only;
    forwarders { 10.10.10.242; 10.10.10.241; };
};
EOF

# проверка конфига на корректность
named-checkconf -p

systemctl start bind

journalctl -efu bind

exit

exit
```

#### Настройка службы BIND на мастера зоны den.skv.
```bash
# Основной сервер локальной сети
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@alt-w-p11-route" \
-i ~/.ssh/id_vm sadmin@alt-s-p11-1

su -

# Заменяем внешние DNS на интерфейсе хоста со статикой
echo "nameserver 10.10.10.254" \
> /etc/net/ifaces/ens6/resolv.conf

# Заменяем внешние DNS на сервере DHCP
# 1 выступает кеширующий сервер шлюза
# 2 Выступает вторичный сервер (slave)
sed -i '11s|77.88.8.8, 77.88.8.1|10.10.10.254, 10.10.10.242|' /etc/dhcp/dhcpd.conf

systemctl stop bind

systemctl restart dhcpd

systemctl restart network
```
##### Проверка работы кеширующего DNS
![](img/5.png)
```bash
cd /var/lib/bind

# даем доступ на dump кеша согласно пути по умолчанию в ./etc/options.conf
chmod g+x var 

# Прослушивать только локальный порт и Loopback интерфейс
sed -i 's/0.1;/0.1; 10.10.10.240\/28;/' etc/options.conf

# Указываем на работу только на IPv4
sed -i 's/S=""/S="-4"/' /etc/sysconfig/bind

# Ограничиваем рекурсию запросов
sed -i 's|//allow-recursion { localnets|allow-recursion { 10.10.10.240/28|' \
etc/options.conf



# разрешаем трансфер до описанных серверов (нужно для вторичного сервера)
sed -i '/::1; };/a\        allow-transfer { localhost; 10.10.10.242; };' etc/options.conf

# ограничиваем оповещение определенным DNS серверам
sed -i '/::1; };/a\        allow-notify { 10.10.10.242; };' etc/options.conf


# проверка конфига на корректность
named-checkconf -p
```
##### Создание ddns зоны
```bash
mkdir zone/ddns

# зона прямого просмотра
cat >>zone/ddns/den.skv.zone<<'EOF'
$TTL 1w
@           IN      SOA     alt-s-p11-1.den.skv. ya.den.skv. (
                              2025110901         ; формат Serial: YYYYMMDDNN, NN - номер ревизии
                              2d                 ; Refresh (2 дня)
                              1h                 ; Retry (2 часа)
                              1w                 ; Expire (1 неделя)
                              1w )               ; Negative Cache TTL (1 неделя)

; Определение серверов имён (NS)
            IN      NS      alt-s-p11-1
            IN      NS      alt-s-p11-2

; Записи A для серверов имён
alt-s-p11-1 IN      A       10.10.10.241
alt-s-p11-2 IN      A       10.10.10.242

; A-запись для самого домена
@           IN      A       10.10.10.241
EOF

# Зона зона обратного просмотра
cat >>zone/ddns/10.10.10.zone<<'EOF'
$TTL 1w
10.10.10.in-addr.arpa.        IN      SOA     alt-s-p11-1.den.skv. ya.den.skv. (
                              2025110901         ; формат Serial: YYYYMMDDNN, NN - номер ревизии
                              2d                 ; Refresh (2 дня)
                              1h                 ; Retry (2 часа)
                              1w                 ; Expire (1 неделя)
                              1w )               ; Negative Cache TTL (1 неделя)

; Определение серверов имён (NS)
                              IN      NS      alt-s-p11-1.den.skv.
                              IN      NS      alt-s-p11-2.den.skv.

; Записи A для серверов имён
241                           IN      PTR     alt-s-p11-1.den.skv.
242                           IN      PTR     alt-s-p11-2.den.skv.
EOF

```
```bash
# Копируем уже имеющийся ключ авторизации для изменения зоны полученный при первом запуске Bind
cp etc/{rndc,ddns}.key

# предоставляем доступ службе bind до скопированного ключа авторизации
chown named:named etc/bind/ddns.key

# Даем уникальное имя для ключа авторизации для обновления зоны ddns
sed -i 's/rndc-key/ddns-key-skv/' etc/ddns.key

# присваиваем данному серверу роль мастера зоны прямого просмотра
cat >>./etc/local.conf<<'EOF'
include "/etc/bind/ddns.key";
zone "den.skv" {
    type master;
    file "ddns/den.skv.zone";
    notify yes;
    allow-update { key ddns-key-skv; };
};
EOF

# присваиваем данному серверу роль мастера зоны прямого просмотра
cat >>./etc/local.conf<<'EOF'

zone "10.10.10.in-addr.arpa" {
    type master;
    file "ddns/10.10.10.zone";
    notify yes;
    allow-update { key ddns-key-skv; };
};
EOF

# проверка конфига на корректность
named-checkconf -p

# Даем доступ службе Bind до созданной зоны
chown named:named -R zone/ddns

# Проверка зоны на корректность
named-checkzone den.skv. zone/ddns/den.skv.zone
```
![](img/6.png)

##### обновление DHCP для обновления ddns зоны
```bash
# Включаем обновление зоны ddns
sed -i '2a\ddns-updates on;' \
/etc/dhcp/dhcpd.conf

# обозначаем механизм добавления записей в зону
sed -i '3s/none;/interim;/' \
/etc/dhcp/dhcpd.conf

# создаем символьную ссылку до файла ключа для обновления записей
ln -s /var/lib/bind/etc/ddns.key /etc/dhcp/

# Указываем путь до ссылки на фал ключа
sed -i '4a\include "/etc/dhcp/ddns.key";' \
/etc/dhcp/dhcpd.conf

# позволяем записывать в зону зарезервированные адреса
sed -i '4a\update-static-leases on;' \
/etc/dhcp/dhcpd.conf

# описываем зону в которую будем автоматически вносить A и TXT записи 
sed -i '/.key";/r /dev/stdin' /etc/dhcp/dhcpd.conf << 'EOF'
zone den.skv {
        primary 10.10.10.241;
        key ddns-key-skv;
}
EOF

# описываем обратную зону в которую будем автоматически вносить PTR записи 
sed -i '/.key";/r /dev/stdin' /etc/dhcp/dhcpd.conf << 'EOF'

zone 10.10.10.in-addr.arpa {
        primary 10.10.10.241;
        key ddns-key-skv;
}

EOF

systemctl restart dhcpd

systemctl restart bind

journalctl -efu bind

exit

exit
```

#### Настройка службы BIND на вторичный сервер зоны den.skv.
```bash
# сервер alt-s-p11-2
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@192.168.121.2" \
-i ~/.ssh/id_vm sadmin@10.10.10.242

su -

systemctl stop bind

cd /var/lib/bind

# даем доступ на dump кеша согласно пути по умолчанию в ./etc/options.conf
chmod g+x var 

# Прослушивать только локальный порт и Loopback интерфейс
sed -i 's/0.1;/0.1; 10.10.10.240\/28;/' etc/options.conf

# Указываем на работу только на IPv4
sed -i 's/S=""/S="-4"/' /etc/sysconfig/bind

# Ограничиваем рекурсию запросов
sed -i 's|//allow-recursion { localnets|allow-recursion { 10.10.10.240/28|' \
etc/options.conf

# Переводим сервер DNS в режим вторичного сервера
control bind-slave enabled

# проверка конфига на корректность
named-checkconf -p
```
```bash
# присваиваем данному серверу роль slave зоны прямого просмотра den.svk
cat >>./etc/local.conf<<'EOF'
zone "den.skv" {
    type slave;
    masters { 10.10.10.241; };
    file "slave/den.skv.zone";
};
EOF

cat >>./etc/local.conf<<'EOF'

zone "10.10.10.in-addr.arpa" {
    type slave;
    masters { 10.10.10.241; };
    file "slave/10.10.10.zone";
};
EOF

# проверка конфига на корректность
named-checkconf -p

systemctl restart bind

journalctl -efu bind

exit

exit
```


##### Для github
```bash

git add . .. ../.. \
&& git status

git log --oneline

git commit -am "оформление для ADM4_lab2_upd5" \
&& git push -u altlinux main
```