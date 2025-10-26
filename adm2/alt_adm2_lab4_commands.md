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
&& virsh start altlinux_altlinux_install


git status

git add .. .

git log --oneline

git commit -am "оформение для 4-ей лабы"

git status

git push -u altlinux main
```
#### После оформения
##### проверка доступности и обновление
```bash
ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm admin@192.168.121.2

su -

ping -c 3 ya.ru

apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get autoremove -y \
&& systemctl reboot
```
##### Выполнение работы
```bash
su -

apt-get install stress -y

lscpu | grep 'CPU('

stress -c 4 -t 30s

top
shft+z \ x \ y \ shift+> \ 1

stress -m 4 -t 30s &

watch free -h

cat /proc/swaps

swapoff -a

cat /proc/swaps

free -m

stress -m 8 -t 30s

watch free -h

stress -m 16 -t 30s

watch free -h

watch 'dmesg | grep kill*'

stress -m 32 -t 30s

watch 'dmesg | grep kill*'
```
### Окончательное Сохранение лабораторной работы 4
```bash
git status

git add . .. \
&& git status

git log --oneline

git commit -am "оформение для 4-ей лабы_END" \
&& git push -u altlinux main
```
