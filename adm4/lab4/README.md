# Лабораторная работа 4 «`Active Directory`»
#### памятка для входа на машины локальной сети
```bash
# включаем агента и запущенному процессу регистрируем используемые ключи
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_vm \
&& ssh-add  ~/.ssh/id_kvm_host_to_vms

# Шлюз и кеширующий сервер DNS
ssh \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route

# Основной DC
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@alt-w-p11-route" \
-i ~/.ssh/id_vm sadmin@10.10.10.241

# сервер вторичный DC
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
git config --global --add safe.directory .

git branch -v

git remote -v


git remote add altlinux https://github.com/shoelacevip12/altlinux_study.git

git log --oneline

git pull altlinux main

cd ~/nfs_git/adm/adm4

mkdir -p lab4/img

cd lab4

touch README.md
```
### Подготовка стенда
```bash
# включаем агента-ssh
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_vm \
&& ssh-add  ~/.ssh/id_kvm_host_to_vms

# Выводим список ВМ стенда для напоминания
sudo virsh list --all

# Выводим список снэпшотов ВМ стенда
sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$2}') ; do \
virsh snapshot-list --domain \$i; done"

# Удаляем снэпшот цепочки основного сервера alt-s-p11-1 после настройки DNS службы
sudo virsh snapshot-delete \
--domain adm4_altlinux_s1 \
--snapshotname 3

# Откатываем основной сервер alt-s-p11-1 на снэпшот до настройки DNS службы
sudo virsh snapshot-revert \
--snapshotname 2 \
--domain adm4_altlinux_s1

# Удаляем снэпшот цепочки сервера alt-s-p11-2 после настройки DNS службы
sudo virsh snapshot-delete \
--domain adm4_altlinux_s2 \
--snapshotname 3

# Откатываем Вторичный сервер alt-s-p11-2 на снэпшот до настройки DNS службы
sudo virsh snapshot-revert \
--snapshotname 2 \
--domain adm4_altlinux_s2

# Откатываем сервер alt-s-p11-3 на снэпшот до настройки standalone SMB сервера
sudo virsh snapshot-revert \
--snapshotname 2 \
--domain adm4_altlinux_s3
```
### Запуск стенда
```bash
# Поочередный запуск всех сетей libvirt со 2ого по списку
sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-start {}

# Запуск шлюза
sudo virsh start \
--domain adm4_altlinux_w2

# Запуск основного DNS сервера
sudo virsh start \
--domain adm4_altlinux_s1

# Поочередный запуск всех ВМ содержащих "nux"
sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$2}') ; do \
virsh start --domain \$i; done"
```
## План для выполнения 
![](img/0.png)

### Обновление и установка клиентских пакетов на всех узлах через Ansible
```bash
cd ../ansible-automation/

# Используем роль для установки BIND, исключив установку BIND
# только обновление пакетов для всех узлов
sed -i 's/soft: true/soft: false/' ./role_bind.yaml

ansible-playbook role_bind.yaml

cd -
```
![](img/1.png)

### Выполнение работы
#### Установка необходимых пакетов для SAMBA-DC
```bash
# Подключение к основному серверу SAMBA-DC
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@alt-w-p11-route" \
-i ~/.ssh/id_vm sadmin@10.10.10.241

su -

# Если присутствую останавливаем конфликтующие службы
systemctl stop smb nmb krb5kdc slapd bind dnsmasq

# Чистка имеющихся настроек SAMBA
rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba
rm -rf /var/cache/samba

# создание каталога для работы Домена
mkdir -p /var/lib/samba/sysvol

# Устанавливаем пакеты для SAMBA-DC и графическое управление его настройками
apt-get install alterator-net-domain task-samba-dc alterator-datetime

# Переименовываем имя сервера согласно FQDN имени домена 
hostnamectl set-hostname alt-s-p11-1.den.skv

# Устанавливаем имя NIS-домена
domainname den.skv

# Меняем на интерфейсе со статикой серверы DNS на внешний (в моем случае на кеширующий с внешними сетями DNS)
cat > /etc/net/ifaces/ens6/resolv.conf<<'EOF'
nameserver 10.10.10.254
EOF

resolvconf -a ens6 < /etc/net/ifaces/ens6/resolv.conf

# перезапускаем службу etcnet управления сетью
systemctl restart network

# перезапускам интерфейс
ifdown ens6; ifup ens6

# проверка работы через кеширующий DNS
cat /etc/resolv.conf

ping ya.ru -c 2
```
#### Создание домена с командной строки
```bash
# –realm задает область Kerberos (LDAP), и DNS имени домена;
# –domain задает имя домена (имя рабочей группы);
# –adminpass пароль основного администратора домена;
# –server-role тип серверной роли.
# –use-rfc2307 схема Совмести UNIX систем с Active Directory 
# при использовании открытых SMB ресурсов sysvol и netlogon на контроллере домена
samba-tool domain provision \
--realm=den.skv \
--domain den \
--adminpass='1qaz@WSX' --dns-backend=SAMBA_INTERNAL \
--server-role=dc \
--use-rfc2307

# Указание прослушивания только интерфейса локальной сети
sed -i '/7 = yes/r /dev/stdin' /etc/samba/smb.conf << 'EOF'
        bind interfaces only = yes
        interfaces = lo ens6
EOF

# Запуск/автозапуск служб Домена
systemctl enable --now samba

# Заменяем ip внешних DNS на самого себя после запуска служб Домена
cat > /etc/net/ifaces/ens6/resolv.conf<<'EOF'
nameserver 127.0.0.1
search den.skv
EOF

resolvconf -a ens6 < /etc/net/ifaces/ens6/resolv.conf

# перезапускаем службу etcnet управления сетью
systemctl restart network

# перезапускам интерфейс
ifdown ens6; ifup ens6

# проверка работы через кеширующий DNS
cat /etc/resolv.conf

# Для сервиса DHCP поменяем внешние DNS на локальные
sed -i 's/77.88.8.8, 77.88.8.1/10.10.10.241, 10.10.10.254/' /etc/dhcp/dhcpd.conf

systemctl restart dhcpd
```
#### Проверка поднятого домена
```bash
systemctl status samba

samba-tool domain info 127.0.0.1

cat /etc/samba/smb.conf
smbclient -L localhost -U Administrator

cat /etc/resolv.conf
ping pub.ru -c 2

host den.skv
host alt-s-p11-1.den.skv
host -t NS den.skv
host -t SRV _kerberos._udp.den.skv
host -t SRV _ldap._tcp.den.skv
```
![](img/2.png)![](img/2.1.png)![](img/2.2.png)![](img/2.3.png)![](img/2.4.png)![](img/2.5.png)

#### Проверка работы Kerberos
```bash
# Заменяем настройки Kerberos для клиентского обращение к серверу созданные доменом
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

# выходим из супер пользователя
exit

# проверка имеющихся белетов kerberos
klist

# удаление имеющихся ключей kerberos
kdestroy

# Получение белета kerberos
kinit Administrator

# Проверка получения белета
klist
```
![](img/3.png)
#### Создание пользователей
```bash
su -

samba-tool user create \
smaba_u1 \
--given-name='Василий Иванович Чапаев' \
--mail-address='chapay_vi@den.skv'

samba-tool user create \
smaba_u2 \
--given-name='Моледцев Владимир Александрович' \
--mail-address='syn_polka@den.skv'

samba-tool user create \
smaba_u3 \
--given-name='Колкин Павел Сергеевич' \
--mail-address='garaj@den.skv'

# Просмотр списка имеющихся пользователей
samba-tool user list

# Подробный просмотр пользователя LDAP 
samba-tool user show smaba_u2

# Разблокировка созданных учетных записей
for n in {1..3}; do \
samba-tool user \
setexpiry smaba_u$n \
--noexpiry; done
```
![](img/4.png)![](img/4.1.png)![](img/4.2.png)![](img/4.3.png)![](img/4.4.png)

#### Создание групп пользователей
```bash
# Создание групп
samba-tool group add \
'Вымышленные_герои'

samba-tool group add \
'Доменные_Администраторы'

# Списки имеющихся групп
samba-tool group list 

# Добавление пользователей в группы
for n in {1..3}; do \
samba-tool group addmembers \
'Вымышленные_герои' \
smaba_u$n ; done

samba-tool group addmembers \
'Доменные_Администраторы' \
smaba_u1

samba-tool group addmembers \
'Domain Admins' \
smaba_u1

# Проверка членства в группах
for g in \
{'Доменные_Администраторы','Вымышленные_герои','Domain Users','Domain Admins'}; do \
echo "---$g---"
samba-tool group listmembers "$g"; done
```
![](img/5.png)
![](img/5.1.png)
![](img/5.2.png)
![](img/5.3.png)
![](img/5.4.png)

#### Подготовка сервера времени к основному SAMBA-DC серверу
```bash
# Перенастраиваем на Московские серверы ВНИИФТРИ ntp3.vniiftri.ru
sed -i 's/pool pool.ntp.org/server ntp3.vniiftri.ru/' \
/etc/chrony.conf

# Указание что данный сервер выступает в роли сервера времени
sed -i 's|#allow 192.168.0.0/16|allow 10.10.10.240/28|' \
/etc/chrony.conf

# Указываем возможность отвечать клиентам, если к внешнему NTP серверу нет доступа
sed -i 's|#local|local|' \
/etc/chrony.conf

# Перезапуск служб NTP
systemctl restart \
chrony-wait.service \
chronyd.service \
chrony.service

# Проверка NTP с новым сервером
chronyc tracking
chronyc sources -v

# Проверка открытого порта для клиентов
ss -ulnp | grep :123
```
![](img/6.png)

#### Подключение хостов к домену
```bash
# Подключение к Рабочей станции станция alt-w-p11-1
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@192.168.121.2" \
-i ~/.ssh/id_vm sadmin@10.10.10.244

su -

# Перезапускаем сетевые службы для обновления DNS по DHCP
systemctl restart network
systemctl restart NetworkManager

# Проверка связи через внешние и локальные DNS
cat /etc/resolv.conf
ping pub.ru -c 2; \
ping den.skv -c 2

cat 
# Переименовываем имя хоста согласно FQDN имени домена 
hostnamectl set-hostname alt-w-p11-1.den.skv

# Перенастраиваем сервер времени на домен контроллер сети alt-s-p11-1
sed -i 's/pool pool.ntp.org/server alt-s-p11-1.den.skv/' \
/etc/chrony.conf

# Перезапуск служб NTP
systemctl restart \
chrony-wait.service \
chronyd.service \
chrony.service

# Проверка NTP с новым сервером
chronyc tracking
chronyc sources -v

# Установка пакетов для авторизации машины в Домен
apt-get update; \
apt-get -y install task-auth-ad-sssd

# Ввод в домен через командную строку 
# alt-w-p11-1 имя вводимого хоста
system-auth write ad \
den.skv alt-w-p11-1 den \
'smaba_u1' '1qaz@WSX'

# Проверка подсоединенного узла
net ads testjoin

ls -ld /etc/krb5*

cat /etc/krb5.conf

id smaba_u{1..3}

getent passwd smaba_u{1..3}
```
![](img/7.png)
![](img/7.1.png)
![](img/7.2.png)
![](img/7.3.png)
![](img/7.4.png)
![](img/7.5.png)
![](img/7.6.png)

### Для github
```bash
git add . .. ../.. \
&& git status

git log --oneline

git commit -am "оформление для ADM4_lab4_upd5" \
&& git push -u altlinux main
```