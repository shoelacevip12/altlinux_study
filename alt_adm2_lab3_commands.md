# Набор удачных команд для Лабораторной работы 3

### Оформление лабараторной работы и подготовка подключения
```bash

git log --oneline

git pull altlinux main

touch alt_adm2_lab3_commands.md

mkdir 3 && cd 3 && mkdir img

touch README.MD

mkdirk img

sudo bash -c "virsh net-start --network vagrant-libvirt \
&& virsh start altlinux_altlinux_install \
&& virsh start altlinux_empty_vm"

git status

git add .. .

git log --oneline

git commit -am "оформение для 3-ей лабы"

git status

git push -u altlinux main
```
#### После оформения
##### подключение к хостам
```bash
ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm admin@192.168.121.2

ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm sadmin@192.168.121.4
```
##### Проверка связности
```bash
ip -br a

ip neighbo

ping -c 3 $(ip neighbo \
| tail -1 \
| awk '{print $1}')
```
##### установка пакетов
```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get -y rsyslog-classic

cat /etc/rsyslog.conf

ls -hr /etc/rsyslog.d/

cat /etc/rsyslog.d/10_classic.conf

cat /etc/rsyslog.d/00_common.conf

systemctl enable --now rsyslog.service

systemctl status rsyslog.service

sed -i 's|#ForwardToSyslog=no|ForwardToSyslog=yes|' /etc/systemd/journald.conf

cat /etc/systemd/journald.conf | grep 'Syslog'

systemctl restart systemd-journald.service

systemctl status systemd-journald.service

cat /etc/syslog.conf | grep "/var/log"

ls -h /var/log
```