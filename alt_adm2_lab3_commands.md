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
&& apt-get install -y rsyslog-classic
```
##### 3.2
```bash
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
##### Установка пакетов на сервере
```bash
apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install -y rsyslog-classic rsyslog-server-listen

systemctl restart rsyslog

systemctl status rsyslog

cat /etc/rsyslog.d/90_server.conf

ss -tulpn | grep 514
```
##### Команды со стороны машины источника данных
```bash
ls -h /etc/rsyslog.d/

echo '*.info  @192.168.121.2:514' \
> /etc/rsyslog.d/08_info_plus.conf

cat /etc/rsyslog.d/08_info_plus.conf

systemctl restart rsyslog

systemctl status rsyslog

cat>test_rlog.sh<<'EOF'
#!/bin/bash
systemctl restart rsyslog crond sshd

echo "ТЕСТ_ПРИОРИТЕОВ_СООБЩЕНИЙ"

LEVELS=("info" "notice" "warn" "err" "crit" "alert" "emerg" "debug" "debug" "debug")

# Перебор уровней
for LEVEL in "${LEVELS[@]}"; do
    logger -p local4."$LEVEL" \
    "level_"$LEVEL"_SKV_DV" \
     && sleep 1 \
     && date \
     && echo "$LEVEL"
done
EOF

chmod +x test_rlog.sh

sh ./test_rlog.sh

su sadmin

exit

sh ./test_rlog.sh
```
##### Команды со стороны сервера логгирования
```bash
cat /dev/null >  /var/log/messages

tail -f /var/log/messages | grep alt-w-p11

ls -h /etc/rsyslog.d

cat>/etc/rsyslog.d/09_categor.conf<<'EOF'
$template   DynFile,"/var/log/%HOSTNAME%/%PROGRAMNAME%.log"
*.*         ?DynFile
EOF

watch ls -lhR /var/log/alt-**
```
#### Сбор данных для отчетности со стороны источника данных
```bash
(cat /etc/syslog.conf \
; cat /etc/rsyslog.conf \
; cat /etc/rsyslog.d/*.conf \
; cat /etc/systemd/journald.conf) \
> vm1.conf

(hostname ; ip a \
| grep 'e[tn].*\: ' -A3) \
> vm1.hostinfo

(ls -la /var/log/ \
; ls -la /var/log/syslog \
; grep -i cron /var/log/syslog/messages) \
> vm1.messages

tail -n 30 /var/log/messages && systemctl \
| grep syslog

cat /etc/systemd/journald.conf

rsync -aP vm1.confs shoel@192.168.121.1:/home/shoel

rsync -aP vm1.hostinfo shoel@192.168.121.1:/home/shoel

rsync -aP vm1.messages shoel@192.168.121.1:/home/shoel

rsync -aP test_rlog.sh shoel@192.168.121.1:/home/shoel
```
#### Сбор данных для отчетности с сервера логгирования
```bash
(cat /etc/syslog.conf \
; cat /etc/rsyslog.conf \
; cat /etc/rsyslog.d/*.conf ) \
> vm2.confs

(hostname ; ip a \
| grep 'e[tn].*\: ' -A3) \
> vm2.hostinfo

(ls -la /var/log/ \
; ls -la /var/log/syslog \
; ls -laR /var/log/alt-w-p11 \
; ls -laR /var/log/alt-s-p11 \
; grep -i cron /var/log/alt-w-p11/systemd.log  \
; grep -i cron /var/log/alt-s-p11/systemd.log) \
> vm2.messages

tail -n 30 /var/log/messages && systemctl \
| grep syslog

rsync -aP vm2.confs shoel@192.168.121.1:/home/shoel

rsync -aP vm2.hostinfo shoel@192.168.121.1:/home/shoel

rsync -aP vm2.messages shoel@192.168.121.1:/home/shoel
```
### Окончательное Сохранение лабораторной работы 3
```bash
git status

git add . .. \
&& git status

git log --oneline

git commit -am "оформение для 3-ей лабы_END" \
&& git push -u altlinux main
```