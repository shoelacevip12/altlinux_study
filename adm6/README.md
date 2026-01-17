# «`Настройка локального стенда ОС Альт`»
### памятка для входа на машины локальной сети
```bash
# включаем агента и запущенному процессу регистрируем используемые ключи
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_vm \
&& ssh-add  ~/.ssh/id_kvm_host_to_vms

# вход через шлюз 192.168.121.2 как прокси на машину локальной сети 10.10.10.241
ssh -i ~/.ssh/id_kvm_host_to_vms \
-o "ProxyJump sadmin@192.168.121.2" \
-i ~/.ssh/id_vm sadmin@10.10.10.241
```

## Предварительно

### Для github и gitflic
```bash
cd ~/altlinux/adm

git init

git config --global \
user.email \
"shoelacevip21@gmail.com"

git config --global \
user.name \
"shoelacevip12"

git config --global \
--add safe.directory .

git remote add \
altlinux \
https://github.com/shoelacevip12/altlinux_study.git

git remote add \
altlinux_gf \
https://gitflic.ru/project/shoelacevip12/altlinux_study.git

git log \
--oneline

git pull \
altlinux main
```
дистрибутивы для платформы x86_64
- Альт Сервер
- Альт Рабочая станция
- [>>Дистрибутивы установки<<](https://getalt.org)
  - [>>Alt p11 server 11.0<<](https://download.basealt.ru/pub/distributions/ALTLinux/p11/images/server/x86_64/alt-server-11.0-x86_64.iso)
  - [>>Alt p11 рабочая станция 11.1<<](https://download.basealt.ru/pub/distributions/ALTLinux/p11/images/workstation/x86_64/alt-workstation-11.1-x86_64.iso)
### Создаем в среде виртуализации libvirt 5 виртуальных машины с общими характеристиками
- 3Гб ОЗУ
- 2 ядро CPU
- Диск размером 40 Гб
- Подсоединяем к ВМ ISO-образы с дистрибутивом Альт Сервера\Рабочая станция
#### своими сетями
- Сеть с сетевым интерфейсом типа bridge для `altlinux_s1` с выходом в интернет через хост машину
- Отдельная сеть с сетевым интерфейсом типа isolated для `altlinux_w1` и `altlinux_s1`
- Отдельная сеть с сетевым интерфейсом типа isolated для `altlinux_s1`, `altlinux_s2` и `altlinux_s4`
- Отдельная сеть с сетевым интерфейсом типа isolated для `altlinux_s1`, и `altlinux_s3`

### Подготовка структуры прохождения курса alt adm6 altnet
```bash
mkdir amd6

cd !$

mkdir -p lab{1..6}/img
```
### Установка vagrant для archlinux
```bash
yay -Ss vagrant

yay -Syu vagrant

vagrant --version
```
### Установка плагинов vagrant для совместимости с libvirt и qemu
```bash
vagrant plugin install \
--plugin-clean-sources \
--plugin-source https://rubygems.org \
vagrant-libvirt vagrant-mutate vagrant-qemu

vagrant plugin repair

vagrant plugin expunge \
--reinstall
```
### скачиваем образы для развертывания altlinux p11
```bash
wget -P \
~/iso/ \
https://download.basealt.ru/pub/distributions/ALTLinux/p11/images/server/x86_64/alt-server-11.0-x86_64.iso

wget -P \
~/iso/ \
https://download.basealt.ru/pub/distributions/ALTLinux/p11/images/workstation/x86_64/alt-workstation-11.1-x86_64.iso
```
#### Создаем файл vagrant для автоматического создания ВМ в количестве 5 шт
```bash
cat>vagrantfile<<'OEF'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Путь к ISO образу ALT Linux p11
  altlinux_iso_path_s = "/home/shoel/iso/alt-server-11.0-x86_64.iso"
  altlinux_iso_path_w = "/home/shoel/iso/alt-workstation-11.1-x86_64.iso"

  # Общие настройки для провайдера libvirt
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.uri = 'qemu:///system'
    libvirt.memory = 3072
    libvirt.cpus = 2
    libvirt.nested = true
    libvirt.disk_driver :cache => 'none'
    libvirt.disk_bus = "virtio"
    libvirt.nic_model_type = "virtio"
    libvirt.storage :file, :size => '40G', :type => 'qcow2'
    libvirt.boot 'hd' # Загрузка с жесткого диска
    libvirt.boot 'cdrom' # Загрузка с CDROM (вторая опция)
    libvirt.management_network_name = "s_host-libvirt"
    libvirt.management_network_mode = "route"
    libvirt.management_network_guest_ipv6 = "no"
  end

  # --- Создание  ВМ для altlinux_s1 ROUTER ---
  config.vm.define "altlinux_s1" do |node_1|
    node_1.vm.hostname = "altlinux-s1" # Устанавливаем имя хоста для ВМ
    node_1.vm.communicator = "none" # Отключаем стандартный communicator (SSH), так как используется ISO

    # Настройки сети: только private_network
    node_1.vm.network "private_network",
                            libvirt__network_name: "s_internet", # Имя создаваемой сети
                            libvirt__forward_mode: "none", # Режим маршрутизации
                            libvirt__dhcp_enabled: false  # Отключаем DHCP в этой сети
    node_1.vm.network "private_network",
                            libvirt__network_name: "s_internal",
                            libvirt__forward_mode: "none",
                            libvirt__dhcp_enabled: false
    node_1.vm.network "private_network",
                            libvirt__network_name: "s_DMZ",
                            libvirt__forward_mode: "none",
                            libvirt__dhcp_enabled: false
    # Настройки провайдера libvirt для конкретной ВМ
    node_1.vm.provider :libvirt do |libvirt|
      libvirt.storage :file, :device => :cdrom, :path => altlinux_iso_path_s
    end

    # Заглушка для provisioner (не запускается)
    node_1.vm.provision "shell", inline: "echo 'altlinux_s1 VM created.'", run: "never"
  end

  # --- Создание 2 ВМ для altlinux_s internet ---
  # Цикл для создания 2-х одинаковых серверных ВМ
  # Все они будут использовать одну и ту же сеть 's_internet'
  [2,4].each do |i|
    config.vm.define "altlinux_s#{i}" do |node_2|
      node_2.vm.hostname = "altlinux-s#{i}" # Устанавливаем имя хоста для ВМ
      node_2.vm.communicator = "none" # Отключаем стандартный communicator (SSH), так как используется ISO

      # Настройки сети: только private_network
      node_2.vm.network "private_network",
                             libvirt__network_name: "s_internet", # Имя создаваемой сети
                             libvirt__forward_mode: "none", # Режим маршрутизации
                             libvirt__dhcp_enabled: false  # Отключаем DHCP в этой сети

      # Настройки провайдера libvirt для конкретной ВМ
      node_2.vm.provider :libvirt do |libvirt|
        libvirt.storage :file, :device => :cdrom, :path => altlinux_iso_path_s
      end

      # Заглушка для provisioner (не запускается)
      node_2.vm.provision "shell", inline: "echo 'altlinux_s#{i} VM created.'", run: "never"
    end
  end

  # --- Создание  ВМ для altlinux_s3 DMZ  ---
  config.vm.define "altlinux_s3" do |node_3|
    node_3.vm.hostname = "altlinux-s1" # Устанавливаем имя хоста для ВМ
    node_3.vm.communicator = "none" # Отключаем стандартный communicator (SSH), так как используется ISO

    # Настройки сети: только private_network
    node_3.vm.network "private_network",
                            libvirt__network_name: "s_DMZ", # Имя создаваемой сети
                            libvirt__forward_mode: "none", # Режим маршрутизации
                            libvirt__dhcp_enabled: false  # Отключаем DHCP в этой сети
    # Настройки провайдера libvirt для конкретной ВМ
    node_3.vm.provider :libvirt do |libvirt|
      libvirt.storage :file, :device => :cdrom, :path => altlinux_iso_path_s
    end
  end

  # --- Создание ВМ для altlinux_w1 ---
    config.vm.define "altlinux_w1" do |node_4|
      node_4.vm.hostname = "altlinux-w1"
      node_4.vm.communicator = "none"
      # Настройки сети: только private_network
      node_4.vm.network "private_network",
                            libvirt__network_name: "s_internal",
                            libvirt__forward_mode: "none",
                            libvirt__dhcp_enabled: false

      node_4.vm.provider :libvirt do |libvirt|
        libvirt.storage :file, :device => :cdrom, :path => altlinux_iso_path_w
        
      end
      node_4.vm.provision "shell", inline: "echo 'altlinux_w1 VM created.'", run: "never"
    end
end
OEF
```
#### Запуск из vagrant для автоматического создания ВМ в количестве 5 шт
```bash
vagrant up \
--no-destroy-on-error

sudo virsh list \
--all
```
#### Принудительная остановка машин и удаление секции DHCP libvirt в созданных сетях
```bash
sudo virsh list \
--all

# Остановка всех ВМ содержащих "nux" 
sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$1}'); do \
virsh destroy \$i; done"

# вывод всех доступных сетей
sudo virsh net-list \
--all

# Остановка всех сетей Libvirt начиная со 2ого по списку
sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-destroy {}
```
##### Удаление DHCP в сети s_host-libvirt для выхода в интернет
```bash
# Запуск редактора сети s_host-libvirt для выхода в интернет
sudo virsh net-edit \
--network \
s_host-libvirt

# экспорт настроек созданных сетей libvirt
sudo virsh net-dumpxml \
s_host-libvirt \
> ./mngt_net.xml
```
```xml
<network>
  <name>s_host-libvirt</name>
  <uuid>9dbf7df8-3ca5-4ca2-8831-d8ff14f38030</uuid>
  <forward mode='route'/>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:ee:56:62'/>
  <ip address='192.168.121.1' netmask='255.255.255.0'>
  </ip>
</network>
```
##### Экспорт настроек других сетей
```bash
sudo virsh net-dumpxml \
s_internal \
> ./s_internal.xml
```
```xml
<network ipv6='yes'>
  <name>s_internal</name>
  <uuid>4bb0d14b-1716-40c3-8ec9-91d6e6f6ff3c</uuid>
  <bridge name='virbr3' stp='on' delay='0'/>
  <mac address='52:54:00:7f:6a:c4'/>
</network>
```
```bash
sudo virsh net-dumpxml \
s_DMZ \
> ./s_DMZ.xml
```
```xml
<network ipv6='yes'>
  <name>s_DMZ</name>
  <uuid>001cbae7-869b-40f6-8908-36aa79b7a5c2</uuid>
  <bridge name='virbr4' stp='on' delay='0'/>
  <mac address='52:54:00:cb:86:b6'/>
</network>
```
```bash
sudo virsh net-dumpxml \
s_internet \
> ./s_internet.xml
```
```xml
<network ipv6='yes'>
  <name>s_internet</name>
  <uuid>14121d01-8caf-43af-b73b-9e199cee8a11</uuid>
  <bridge name='virbr2' stp='on' delay='0'/>
  <mac address='52:54:00:c4:92:02'/>
</network>
```
##### Удаление mgt-сеть `s_host-libvirt` со всех виртуальных машин кроме adm4_altlinux_s1
```bash
# определяем список виртуальных машин поименно кроме adm4_altlinux_s1
sudo bash -c \
"virsh list --all \
| awk '/nux/ && !/x_s1/ {print \$2}'"

# определяем мак адреса интерфейсов для отключения
sudo bash -c \
"virsh list --all \
| awk '/nux/ && !/x_s1/ {print \$2}' \
| xargs -I {} virsh dumpxml {} \
| grep -B1 s_host-libvirt" \
| sed -n "s/.*<mac address='\([^']*\)'.*/\1/p"

# поочередное удаление интерфейсов выхода в интернет 
sudo virsh detach-interface \
adm6_altlinux_s2 \
--type network \
--mac 52:54:00:0e:da:0c \
--config

sudo virsh detach-interface \
adm6_altlinux_s3 \
--type network \
--mac 52:54:00:f6:a3:f2 \
--config

sudo virsh detach-interface \
adm6_altlinux_s4 \
--type network \
--mac 52:54:00:72:e9:84 \
--config

sudo virsh detach-interface \
adm6_altlinux_w1 \
--type network \
--mac 52:54:00:97:4b:d3 \
--config

# Экспорт настроек созданных ВМ
sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$2}') ; do \
virsh dumpxml \$i \
> \$i.xml; done"

sudo chmod 777 *.xml
```
### Для github и gitflic
```bash
git branch -v

git log --oneline

git switch main

git status

git rm -r --cached . ..

git add . .. \
&& git status

git remote -v

git commit -am "оформление для ADM6 развертка стенда" \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```
![](img/0.png)
#### Запуск отредактированной сети, виртуальных машин
```bash
# поочередный запуск всех сетей libvirt со 2ого по списку
sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-start {}

# поочередный запуск всех ВМ содержащих "nux"
sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$2}') ; do \
virsh start --domain \$i; done"

# добавление статических маршрутов с хостовой машины до изолированных сетей между ВМ
sudo ip route \
add 10.1.1.240/28 \
via 192.168.121.2 \
dev virbr1

sudo ip route \
add 10.0.0.0/24 \
via 192.168.121.2 \
dev virbr1

sudo ip route \
add 10.20.20.240/28 \
via 192.168.121.2 \
dev virbr1
```
#### Ручная установка ОС Альт.

![](../adm4/img/1.png)![](../adm4/img/2.png)![](../adm4/img/8.png)

#### Организация – маршрутизации на узле с 4-мя сетевыми интерфейсами

![](../adm4/img/11.png)

##### Донастройка сетей `s_internet`, `s_internal`,`s_DMZ` на узле `alt-s-p11-route`

![](img/1.png) ![](img/2.png)

```bash
# вход на bastion хост по паролю по ssh
> ~/.ssh/known_hosts \
&& ssh -t -o StrictHostKeyChecking=accept-new \
sadmin@192.168.121.2 \
"su -"

ip a \
| grep -A1 "ens"

# копируем настройки статических адресов для интерфейса с сетью s_internet
cp /etc/net/ifaces/ens{5,6}/options

# статический адрес для сети s_internet
echo '10.0.0.254/24' \
> /etc/net/ifaces/ens6/ipv4address

# копируем настройки статических адресов для интерфейса с сетью s_internal
cp /etc/net/ifaces/ens{5,7}/options

# статический адрес для сети s_internal
echo '10.1.1.254/28' \
> /etc/net/ifaces/ens7/ipv4address


# копируем настройки статических адресов для интерфейса с сетью s_DMZ
cp /etc/net/ifaces/ens{5,8}/options

# статический адрес для сети s_DMZ
echo '10.20.20.254/28' \
> /etc/net/ifaces/ens8/ipv4address

systemctl restart network
```
![](img/3.png) ![](img/4.png)
##### Промежуточное сохранение(snapshot) машины
```bash
systemctl poweroff

# Создание snapshot
### Основного сервера сети
sudo virsh snapshot-create-as \
--domain adm6_altlinux_s1 \
--name 1 \
--description "before_routing" --atomic

# запуск ВМ alt-s-p11-route
sudo virsh start \
--domain adm6_altlinux_s1
```
### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. \
&& git status

git remote -v

git commit -am 'оформление для ADM6 развертка стенда 2' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```
##### настройка nftables для узла стенда
```bash
# вход на bastion хост по паролю по ssh
> ~/.ssh/known_hosts \
&& ssh -t -o StrictHostKeyChecking=accept-new \
sadmin@192.168.121.2 \
"su -"

# включение внутренней маршрутизации пакетов между интерфейсами
sed -i 's/rd\ =\ 0/rd\ =\ 1/' \
/etc/net/sysctl.conf

systemctl restart network

# обновление системы и установка пакетов для nat-маршрутизации
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y \
nftables \
tree

# Включаем и добавляем в автозагрузку службу nftables:
systemctl enable --now \
nftables

# Создаём необходимую структуру для nftables (семейство, таблица, цепочка) для настройки NAT:
## где ens5 это интерфейс s_host-libvirt с выходом в реальную WAN сеть 
nft add table ip nat
nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'
nft add rule ip nat postrouting ip saddr 10.1.1.240/28 oifname "ens5" counter masquerade
nft add rule ip nat postrouting ip saddr 10.0.0.0/24 oifname "ens5" counter masquerade
nft add rule ip nat postrouting ip saddr 10.20.20.240/28 oifname "ens5" counter masquerade

# Сохраняем правила nftables
nft list ruleset \
| tail -n8 \
| tee -a /etc/nftables/nftables.nft

systemctl reboot

su -

systemctl status \
nftables

nft list ruleset
```
![](img/4.png)
##### Промежуточное сохранение(snapshot) машины
```bash
# выключение машины
systemctl poweroff

# вывод списка snapshot хоста
sudo virsh snapshot-list \
adm6_altlinux_s1

# удаление снимка
sudo virsh snapshot-delete \
--domain adm6_altlinux_s1 \
--snapshotname 1

# Создание snapshot
### Основного сервера сети
sudo virsh snapshot-create-as \
--domain adm6_altlinux_s1 \
--name 1 \
--description "before_dhcp-server" --atomic

# запуск ВМ alt-s-p11-route
sudo virsh start \
--domain adm6_altlinux_s1
```
### Для github и gitflic
```bash
git log --oneline

git branch -v

git switch main

git status

git add . .. \
&& git status

git remote -v

git commit -am 'оформление для ADM6 развертка стенда, проброс интернета' \
&& git push \
--set-upstream \
altlinux \
main \
&& git push \
--set-upstream \
altlinux_gf \
main
```