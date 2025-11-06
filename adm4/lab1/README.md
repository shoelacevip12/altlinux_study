# Лабораторная работа 1. «`Настройка DHCP-серверав ОС Альт`» `Скворцов Денис`
### Предварительно

##### Для github
```bash
cd ~/altlinux/adm

git init

git config --global user.email "shoelacevip21@gmail.com"

git config --global user.name "shoelacevip12"

git config --global --add safe.directory .

git remote add altlinux https://github.com/shoelacevip12/altlinux_study.git

git log --oneline

git pull altlinux main
```
дистрибутивы для платформы x86_64
• Альт Сервер
• Альт Рабочая станция
[>>Дистрибутива устновки<<](https://getalt.org)
##### Создаем в среде виртуализации libvirt 2 виртуальные машины с характеристиками
• 4Гб ОЗУ
• 2 ядро CPU
• 1 сетевой интерфейс (типа bridge)
• Диск размером не менее 30 Гб
• Подсоедините к ВМ ISO-образ с дистрибутивом Альт Сервера 

```bash
mkdir amd4

cd !$

mkdir -p lab1/img

wget -P /home/shoel/iso/ https://download.basealt.ru/pub/distributions/ALTLinux/p11/images/server/x86_64/alt-server-11.0-x86_64.iso
wget -P /home/shoel/iso/ https://download.basealt.ru/pub/distributions/ALTLinux/p11/images/workstation/x86_64/alt-workstation-11.1-x86_64.iso

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
    libvirt.management_network_name = "vagrant-libvirt"
    libvirt.management_network_mode = "route"
    # libvirt.management_network_mode = "none" # Альтернатива route, если dhcp_enabled не срабатывает
    libvirt.management_network_guest_ipv6 = "no"
  end

  # --- Создание 3 ВМ для altlinux_s ---
  # Цикл для создания трёх одинаковых серверных ВМ
  # Все они будут использовать одну и ту же сеть 's_private_network'
  (1..3).each do |i|
    config.vm.define "altlinux_s#{i}" do |node_2|
      node_2.vm.hostname = "altlinux-s#{i}" # Устанавливаем имя хоста для ВМ
      node_2.vm.communicator = "none" # Отключаем стандартный communicator (SSH), так как используется ISO

      # Настройки сети: только private_network
      node_2.vm.network "private_network",
                             libvirt__network_name: "s_private_network", # Имя создаваемой сети
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

  # --- Создание 2 ВМ для altlinux_w ---
  # Цикл для создания двух одинаковых desktop ВМ
  # Все они будут использовать одну и ту же сеть 's_private_network'
  (1..2).each do |i|
    # --- Создание 2 ВМ для altlinux_w ---
    config.vm.define "altlinux_w#{i}" do |node_3|
      # Исправлено: имя хоста должно зависеть от переменной цикла i
      node_3.vm.hostname = "altlinux-w#{i}"
      node_3.vm.communicator = "none"
      # Настройки сети: только private_network
      node_3.vm.network "private_network",
                            libvirt__network_name: "s_private_network",
                            libvirt__forward_mode: "none",
                            libvirt__dhcp_enabled: false

      node_3.vm.provider :libvirt do |libvirt|
        libvirt.storage :file, :device => :cdrom, :path => altlinux_iso_path_w
        
      end
      node_3.vm.provision "shell", inline: "echo 'altlinux_w#{i} VM created.'", run: "never"
    end
  end
end
OEF

vagrant up --no-destroy-on-error

sudo virsh list --all
```
##### Принудительная остановка машин и удаление секции DHCP libvirt поднятой сети
```bash
sudo virsh list --all

sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$1}'); do \
virsh destroy \$i; done"

sudo virsh net-list --all

sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-destroy {}

sudo virsh net-edit --network vagrant-libvirt

sudo virsh net-dumpxml vagrant-libvirt \
> ./mngt_net.xml

sudo chmod 777 !$
```
```xml
<network>
  <name>vagrant-libvirt</name>
  <uuid>5cb32edc-2eeb-4054-a4a3-e66c54106877</uuid>
  <forward mode='route'/>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:b6:12:f7'/>
  <ip address='192.168.121.1' netmask='255.255.255.0'>
  </ip>
</network>
```


##### Удаление постоянного интерфейса со всех виртуальных машин кроме adm4_altlinux_w2
```bash
# определяем список виртуальных машин поименно
sudo bash -c \
"virsh list --all \
| awk '/nux/ && !/x_w2/ {print \$2}'"

# определяем мак адреса интерфесов для отключения
sudo bash -c \
"virsh list --all \
| awk '/nux/ && !/x_w2/ {print \$2}' \
| xargs -I {} virsh dumpxml {} \
| grep -B1 vagrant-libvir" \
| sed -n "s/.*<mac address='\([^']*\)'.*/\1/p"

# поочередное отключение интерфейсов
sudo virsh detach-interface \
adm4_altlinux_s1 \
--type network \
--mac 52:54:00:fa:48:ad \
--config

sudo virsh detach-interface \
adm4_altlinux_s2 \
--type network \
--mac 52:54:00:81:6e:fb \
--config

sudo virsh detach-interface \
adm4_altlinux_s3 \
--type network \
--mac 52:54:00:8b:0b:c9 \
--config

sudo virsh detach-interface \
adm4_altlinux_w1 \
--type network \
--mac 52:54:00:1c:86:b6 \
--config

sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$2}') ; do \
virsh dumpxml \$i \
> \$i.xml; done"

sudo chmod 777 *.xml
```
##### Запуск отредактированной сети и виртуальных машин
```bash
sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-start {}

sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$2}') ; do \
virsh start --domain \$i; done"
```

##### Ручная установка ОС Альт Сервер.

![](img/1.png)![](img/2.png)![](img/3.png)![](img/4.png)![](img/5.png)![](img/5.1.png)

##### Организовываем подключение к серверному узлу
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_kvm_host -C "kvm-host-access-key"
ssh-keygen -t ed25519 -f ~/.ssh/id_vm -C "vm-access-key"

ssh-copy-id -i ~/.ssh/id_kvm_host.pub shoel@shoellin

ssh-copy-id -i ~/.ssh/id_vm.pub -o "ProxyJump shoel@shoellin" sadmin@192.168.121.2

ssh -i D:\Users\shoel\AppData\Roaming\MobaXterm\home\.ssh\id_kvm_host -o "ProxyJump shoel@shoellin" -i D:\Users\shoel\AppData\Roaming\MobaXterm\home\.ssh\id_vm sadmin@192.168.121.2

su -

ip -br a

systemctl enable --now qemu-guest-agent.service

exit

exit

sudo virsh dumpxml altlinux_altlinux_install > ./altlinux_server.xml

# sudo virsh snapshot-create-as --domain altlinux_altlinux_install --name 1 --description "1" --atomic

# sudo virsh snapshot-delete altlinux_altlinux_install --snapshotname 1
```

![](img/6.png)

##### Для github
```bash
git add . .. \
&& git status

git log --oneline

git commit -am "оформение для ADM4" \
&& git push -u altlinux main
```
