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
```bash
ip -br a

ip neighbo

ping -c 3 $(ip neighbo \
| tail -1 \
| awk '{print $1}')



```