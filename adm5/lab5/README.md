# Лабораторная работа 5 «`Использование GnuPG`»
#### памятка для входа на машины локальной сети
```bash
# включаем агента и запущенному процессу регистрируем используемые ключи
eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_vm \
&& ssh-add  ~/.ssh/id_kvm_host_to_vms

# Рабочая станция p11
ssh \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route
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

mkdir -p adm5/{lab5,img}

cd adm5/lab5

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

# Выводим список снэпшотов ВМ стенда
sudo bash -c \
"for i in \$(virsh list --all \
| awk '/nux/ {print \$2}') ; do \
echo "\$i" && \
virsh snapshot-list --domain \$i; done"

# Откатываем хост adm4_altlinux_w2 на снэпшот 5 из-за отключенной флешки на хосте
sudo virsh snapshot-revert \
--snapshotname 5 \
--domain adm4_altlinux_w2

# Запуск Рабочей станции p11
sudo virsh start \
--domain adm4_altlinux_w2
```

### Выполнение работы
```bash
# Проброс публичного ключа chelin_pub.gpg на хост
rsync -aP \
chelin_pub.gpg \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route:/home/sadmin

# вход на хост
ssh \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route

su -

# обновление системы и установка gnupg и gnupg2
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y gnupg gnupg2


```
### Тестирование 1
```bash

```

### Тестирование 2
```bash

```

### Для github
```bash
git add . .. ../.. \
&& git status

git log --oneline

git commit -am "оформление для ADM5_lab5_upd1" \
&& git push -u altlinux main
```