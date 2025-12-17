# Лабораторная работа 7 «`OpenVPN`»
#### памятка для снепшотов и входа на машины локальной сети
```bash
# включаем агента и запущенному процессу регистрируем используемые ключи
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_vm \
&& ssh-add  ~/.ssh/id_kvm_host_to_vms

# Рабочая станция p11
ssh \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route


#### Создание snapshot
sudo virsh snapshot-create-as \
--domain adm4_altlinux_w2 \
--name 7 \
--description "before_adm5_lab7" --atomic

# Откатываем на снэпшот 6
sudo virsh snapshot-revert \
--snapshotname 7 \
--domain adm4_altlinux_w2

# Удаляем снэпшот цепочки 6
sudo virsh snapshot-delete \
--domain adm4_altlinux_w2 \
--snapshotname 6
```

## Предварительно
### Для github
```bash
cd nfs_git/adm

git config --global --add safe.directory .

git branch -v

git remote -v

git remote add altlinux https://github.com/shoelacevip12/altlinux_study.git

git log --oneline

git pull altlinux main

mkdir -p adm5/{lab7,lab7/img}

cd adm5/lab7

touch README.md
```

### Подготовка и запуск стенда
```bash
# включаем агента-ssh
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_vm \
&& ssh-add  ~/.ssh/id_kvm_host_to_vms

# Выводим список ВМ стенда для напоминания
sudo virsh list --all

# Поочередный запуск всех сетей libvirt со 2ого по списку
sudo virsh net-list --all \
| awk 'NR > 3 {print $1}' \
| xargs -I {} sudo virsh net-start {}

# Запуск Рабочей станции p11
sudo virsh start \
--domain adm4_altlinux_w2
```

#### Подготовка для работы с yandex cloud
```bash
# вход на хост
ssh \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route

# Скачиваем скрипт для установки yandex console
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh \
| bash

# Применение новых переменных окружения в текущей сессии
source \
~/.bashrc 

# инициализация подключения к уже созданному аккаунту yandex cloud
yc init
https://oauth.yandex.ru/authorize?response_type=token&client_id=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
y0__xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
1
Y
1
```
```bash
# Вывод списка аккаунтов управления (сервисный аккаунт) для работы с новыми виртуальными машинами
yc iam service-account list
```
```bash
+----------------------+----------------------+--------+---------------------+-----------------------+
|          ID          |         NAME         | LABELS |     CREATED AT      | LAST AUTHENTICATED AT |
+----------------------+----------------------+--------+---------------------+-----------------------+
| ajxxxxxxxxxxxxxxxxxx | xxx-tesxxt           |        | 2025-12-10 07:49:05 |                       |
| ajxxxxxxxxxxxxxxxxxx | xxx-xxx-xxx-xxxxxxxx |        | 2025-12-10 01:49:46 |                       |
| ajxxxxxxxxxxxxxxxxxx | xxx                  |        | 2025-07-13 13:12:35 | 2025-12-17 19:50:00   |
+----------------------+----------------------+--------+---------------------+-----------------------+
```
```bash
# Добавления новых переменных окружения для авторизации на yandex cloud
cat >> .bashrc <<'EOF'
export YC_TOKEN=$(yc iam create-token --impersonate-service-account-id ajxxxxxxxxxxxxxxxxxx)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
EOF

# Применение переменных окружения
source .bashrc

su -

# обновление системы и установка openvpn easy-rsa на клиенте соединения
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y openvpn easy-rsa

# Скрипт установки последнего доступного terraform с зеркала yandex cloud
cat > terraform_for_altlinux.sh <<'EOF'
#!/bin/bash -x

# CREATED:
# vitaliy.natarov@yahoo.com
# Unix/Linux blog:
# http://linux-notes.org
# Vitaliy Natarov

# RECREATED:
# ArtamonovKA
# For AltLinux

#MODED:
#17.12.25
#Shoelacevip12
#For AltLinux p11 workstation

function install_terraform () {
        #
        if [ -f /etc/altlinux-release ] || [ -f /etc/redhat-release ] ; then
                #update OS
                apt-get update &> /dev/null -y && apt-get dist-upgrade &> /dev/null -y
                #
                if ! type -path "wget" > /dev/null 2>&1; then apt-get install wget &> /dev/null -y; fi
                if ! type -path "curl" > /dev/null 2>&1; then apt-get install curl &> /dev/null -y; fi
                if ! type -path "unzip" > /dev/null 2>&1; then apt-get install unzip &> /dev/null -y; fi
        OS=$(lsb_release -ds|cut -d '"' -f2|awk '{print $1}')
        OS_MAJOR_VERSION=$(sed -rn 's/.*([0-9]).[0-9].*/\1/p' /etc/redhat-release)
                OS_MINOR_VERSION=$(cat /etc/redhat-release | cut -d"." -f2| cut -d " " -f1)
                Bit_OS=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
                echo "$OS-$OS_MAJOR_VERSION.$OS_MINOR_VERSION with $Bit_OS bit arch"
                #
                site="https://hashicorp-releases.yandexcloud.net/terraform/"
        Latest_terraform_version=$(curl -s "$site" --list-only | grep -E "terraform_" | grep -Ev "beta|alpha" | head -n1| cut -d ">" -f2| cut -d "<" -f1 | cut -d"_" -f2)
        URL_with_latest_terraform_package=$site$Latest_terraform_version
                #
                if [ "`uname -m`" == "x86_64" ]; then
                        Latest_terraform_package=$(curl -s "$URL_with_latest_terraform_package/" --list-only |grep -E "terraform_" | grep -E "linux_amd64"|cut -d ">" -f2| cut -d "<" -f1)
                        Current_link_to_archive=$URL_with_latest_terraform_package/$Latest_terraform_package
                elif [ "`uname -m`" == "i386|i686" ]; then
                        Latest_terraform_package=$(curl -s "$URL_with_latest_terraform_package/" --list-only |grep -E "terraform_" | grep -Ev "(SHA256SUMS|windows)"| grep -E "linux_386"|cut -d ">" -f2| cut -d "<" -f1)
                        Current_link_to_archive=$URL_with_latest_terraform_package/$Latest_terraform_package
                fi
                echo $Current_link_to_archive
                mkdir -p /usr/local/src/ && cd /usr/local/src/ && wget $Current_link_to_archive &> /dev/null
                unzip -o $Latest_terraform_package
                rm -rf /usr/local/src/$Latest_terraform_package*
                yes|mv -f /usr/local/src/terraform /usr/local/bin/terraform
                chmod +x /usr/local/bin/terraform
        else
        OS=$(uname -s)
        VER=$(uname -r)
        echo 'OS=' $OS 'VER=' $VER
        fi
}
install_terraform
echo "========================================================================================================";
echo "================================================FINISHED================================================";
echo "========================================================================================================";
EOF

# Делаем скрипт исполняемым
chmod +x terraform_for_altlinux.sh

# Запуск скрипта установки
./terraform_for_altlinux.sh

# выход из-под супер пользователя
exit

# указываем источник (yandex cloud), из которого будет устанавливаться провайдер
cat > .terraformrc << 'EOF'
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF

exit

# в папке с проектом создаем конфигурационный файл .tf:
# source — глобальный адрес источника провайдера.
# required_version — минимальная версия Terraform, с которой совместим провайдер.
# provider — название провайдера.
# zone — зона доступности, в которой по умолчанию будут создаваться все облачные ресурсы.
cat > providers.tf <<'EOF'
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "<зона_доступности_по_умолчанию>"
}
EOF

# в папке с проектом создаем отдельный конфигурационный файл .tf:
# где будет расписан какой образ из репозитория будет использоваться
# с какими параметрами
# Сетями
# Будет созданы виртуальные машины
cat > vms.tf <<'EOF'
#считываем данные об образе ОС
data "yandex_compute_image" "altserver" {
  family = "basealt-altserver"
}

resource "yandex_compute_instance" "openvpn-altserver" {
  name        = "openvpn-altserver"
  hostname    = "openvpn-altserver"
  platform_id = "standard-v2"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = var.srv.cores
    memory        = var.srv.memory
    core_fraction = var.srv.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.altserver.image_id
      type     = "network-hdd"
      size     = 20
    }
  }

  metadata = {
    # user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.skv_a.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.openvpn-altserver.id]
  }
}
EOF

# в папке с проектом создаем отдельный конфигурационный файл .tf:
# с часто повторяющимися переменными в других файлах.tf
cat > variables.tf <<'EOF'
variable "dz" {
  type    = string
  default = "lab7-openvpn"
}

variable "cloud_id" {
  type    = string
  default = "b1gkumrn87pei2831blp"
}
variable "folder_id" {
  type    = string
  default = "b1g7qviodfc9v4k81sr5"
}

variable "srv" {
  type = map(number)
  default = {
    cores         = 4
    memory        = 4
    core_fraction = 20
  }
}
EOF

# в папке с проектом создаем отдельный конфигурационный файл .tf:
# с описанием структуры сетей и доступа
cat > network.tf <<'EOF'
#Общая облачная сеть yandex
resource "yandex_vpc_network" "skv" {
  name = "skv-adm5-${var.dz}"
}

#Подсеть zone A
resource "yandex_vpc_subnet" "skv_a" {
  name           = "skv-adm-${var.dz}-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.skv.id
  v4_cidr_blocks = ["10.10.10.0/26"]
  route_table_id = yandex_vpc_route_table.route.id
}

#Сеть под NAT
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "adm-gateway-${var.dz}"
  shared_egress_gateway {}
}

#Шлюз для выхода в WAN
resource "yandex_vpc_route_table" "route" {
  name       = "adm-route-table-${var.dz}"
  network_id = yandex_vpc_network.skv.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

##Правила NAT
#Разрешаем Всем Входящие соединения по 22 порту по протоколу TCP, необходимо для proxy-jump
#Разрешаем Всем входящие соединения по протоколу TCP по 80,443 портам
#Разрешаем Всем входящие соединения по протоколу TCP по 10051
resource "yandex_vpc_security_group" "openvpn-altserver" {
  name       = "openvpn-altserver-${var.dz}"
  network_id = yandex_vpc_network.skv.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    description    = "Allow HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Allow openvpn"
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#Разрешаем всем из-под внутренних подсетей zone выход на любые ресурсы по любому протоколу
resource "yandex_vpc_security_group" "LAN" {
  name       = "LAN-${var.dz}"
  network_id = yandex_vpc_network.skv.id
  ingress {
    description    = "Allow 10.10.10.0/26"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.10.10.0/26"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}
EOF
```
#### Подготовка Тестовый Запуск
```bash
terraform init

terraform validate \
&& terraform fmt  \
&& terraform init --upgrade \
&& terraform plan -out=tfplan

terraform apply "tfplan"

terraform destroy
```
![](./img/1.png)![](./img/2.png)![](./img/3.png)![](./img/4.png)![](./img/5.png)

### Для github
```bash
git add . .. ../.. \
&& git status

git log --oneline

git commit -am "оформление для ADM5_lab7_upd3" \
&& git push -u altlinux main
```