# Лабораторная работа 3 «`Настройка регулярного запуска OSEC`»
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

mkdir -p adm5/{lab3,img}

cd  adm5/lab3

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

### Выполнение работы
```bash
# вход на хост
ssh \
-i ~/.ssh/id_kvm_host_to_vms \
sadmin@alt-w-p11-route

su -

# обновление системы и установка osec и osec-cronjob
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y osec-cronjob

# Копирование unit-таймера для расписания работы osec 
cp /lib/systemd/system/osec.timer /etc/systemd/system/osec.timer

# Организация с использованием механизма таймеров systemd:
sed -i -e 's/Run OSEC every day at midnight/Запуск через 5 минут после загрузки системы и потом каждые 3 часа/' \
-e '/^OnCalendar=\*-\*-\* 3:00$/c\OnBootSec=5min\nOnUnitActiveSec=3h' \
-e '/^RandomizedDelaySec=60m$/d' \
/etc/systemd/system/osec.timer
```
### Проверка таймер-unit`а
```bash
systemctl cat osec.timer
```
```ini
# /etc/systemd/system/osec.timer
[Unit]
Description=Запуск через 5 минут после загрузки системы и потом каждые 3 часа

[Timer]
OnBootSec=5min
OnUnitActiveSec=3h

[Install]
WantedBy=multi-user.target
```
### Обновление списка unit`ов и активация расписания запуска скрипта osec 
```bash
systemctl daemon-reload
systemctl enable --now osec.timer
```
### Проверка журнала запуска
```bash
journalctl -efu osec*
```
![](./img/1.png)

### Для github
```bash
git add . .. ../.. \
&& git status

git log --oneline

git commit -am "оформление для ADM5_lab3_upd1" \
&& git push -u altlinux main
```