# Набор удачных коман для Лабораторной работы 2
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

git status

git add .. .

git log --oneline

git commit -am "оформение для 2-ой лабы"

git status

git push -u altlinux main
```