# Набор удачных команд для Лабораторной работы 4

### Оформление лабараторной работы и подготовка подключения
```bash

git log --oneline

git pull altlinux main

touch alt_adm2_lab4_commands.md

mkdir 4 && cd 4 && mkdir img

touch README.MD

mkdirk img

sudo bash -c "virsh net-start --network vagrant-libvirt \
&& virsh start altlinux_altlinux_install \


git status

git add .. .

git log --oneline

git commit -am "оформение для 4-ей лабы"

git status

git push -u altlinux main
```
#### После оформения
##### подключение к хостам
```bash
ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm admin@192.168.121.2

su -

ping -c 3 ya.ru
```
