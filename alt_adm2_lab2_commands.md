# Набор удачных команд для Лабораторной работы 2

### Оформление лабараторной работы и подготовка подключения
```bash

git init

git config --global user.email "shoelacevip21@gmail.com"

git config --global user.name "shoelacevip12"

git config --global --add safe.directory '%(prefix)///synshoel/git/VM/alt/ADM2'

git branch -M main

git add .

git status

git commit -am "1ый_пошел"

git status

git remote add altlinux https://github.com/shoelacevip12/altlinux_study.git

git remote

git push -u altlinux main

git log --oneline

git pull altlinux main

mkdir 2 && cd 2

touch README.MD

mkdirk img

sudo virsh net-list --all

sudo virsh net-start --network vagrant-libvirt

sudo virsh list --all

sudo virsh start altlinux_altlinux_install

sudo virsh start altlinux_empty_vm

ssh-keygen -t ed25519 \
-f ~/.ssh/id_kvm_host \
-C "kvm-host-access-key"

ssh-keygen -t ed25519 \
-f ~/.ssh/id_vm \
-C "vm-access-key"

ssh-copy-id -i ~/.ssh/id_kvm_host.pub shoel@shoellin

ssh -o "ProxyJump=shoel@shoellin" \
sadmin@192.168.121.4 \
"mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/id_vm.pub

ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm sadmin@192.168.121.4

exit

git status

git add .. .

git log --oneline

git commit -am "оформение для 2-ой лабы"

git status

git push -u altlinux main
```
### После оформения, 
### Выполнение работы 1-4
```bash
ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm sadmin@192.168.121.4

su -

runlevel

systemctl get-default

systemctl reboot

su -

which bash

systemctl reboot

ssh -t -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm sadmin@192.168.121.4 \
"su -"

sed -i "4a\\nameserver 77.88.8.8" /etc/resolv.conf

reboot

apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install git -y

git clone https://github.com/hse-labs/linux-lf.git

rm -rf linux-lf/.git

cat linux-lf/fake.service

ls /etc/systemd/system

ls /lib/systemd/system

cp -v linux-lf/fake.service /etc/systemd/system/

file /etc/systemd/system/fake.service

ls -l /etc/systemd/system/fake.service

systemctl start fake.service \
&& systemctl status fake
systemctl restart fake \
&& systemctl stop fake \
&& systemctl enable fake
```
### Сохранение текущей работы
```bash
git status

git add . .. \
&& git status

git log --oneline

git commit -am "для 2-ой лабы_1-4" \
&& git push -u altlinux main
```
### Выполнение работы 5-7
```bash
systemctl status cups

systemctl disable cups

systemctl status cups

runlevel

systemctl isolate multi-user.target

runlevel

systemctl status cups

systemctl cat cups

systemctl isolate graphical.target

systemctl status cups

systemctl enable cups

cat /etc/systemd/journald.conf \
| grep -E "(Storage|ForwardToSyslog)"

ls -hR /run/log/journal

df -h

ls -hR /run/log/

journalctl -k -n15 -o cat

journalctl $(which sshd) -e

journalctl _UID=$(id -u sadmin) -e

journalctl -b

journalctl -xe

journalctl -b -p err > /tmp/err_1

rsync -aP /tmp/err_1 shoel@"$(ip neighbo | awk '{print $1}')":/home/shoel
```

### Окончательное Сохранение лабораторной работы 2
```bash
git status

git add . .. \
&& git status

git log --oneline

git commit -am "для 2-ой лабы_END" \
&& git push -u altlinux main
```