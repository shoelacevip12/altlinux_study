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
##### обновление системы и установка пакетов для DNS-серверов
```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y \
dhcp-server

### Выполнение работы
```bash

```

##### Для github
```bash

git add . .. ../.. \
&& git status

git log --oneline

git commit -am "оформление для ADM4_lab2_upd1" \
&& git push -u altlinux main
```