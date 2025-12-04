# Лабораторная работа 2 «`Настройка требований сложности пароля`»
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

mkdir -p adm5/lab2

cd !$

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

# Выполните настройку требований сложности паролей пользователей, согласно следующим параметрам:
# 1. Одноклассовые пароли использовать нельзя
# 2. Минимальная длина двуклассовых - 16 символов
# 3. Минимальная длина парольных фраз - 12 символов
# 4. Трехклассовых - 12
# 5. Четырехклассовых - 8
sed -i 's/^min=[0-9,]*$/min=disabled,16,12,12,8/' \
/etc/passwdqc.conf

# Парольная фраза должна состоять из трех слов как минимум
sed -i 's/^passphrase=[0-9]*$/passphrase=3/' \
/etc/passwdqc.conf

# Применять пароль к суперпользователю
sed -i 's/^enforce=[A-Za-z]*$/enforce=everyone/' \
/etc/passwdqc.conf

cat !$
```
###
```ini
min=disabled,16,12,12,8
max=72
passphrase=3
match=4
similar=deny
random=47
enforce=everyone
retry=3
# The below are just examples, by default none of these are used
#wordlist=/usr/share/john/password.lst
#denylist=/etc/passwdqc.deny
#filter=/opt/passwdqc/hibp.pwq
```
### Для github
```bash
git add . .. ../.. \
&& git status

git log --oneline

git commit -am "оформление для ADM5_lab2" \
&& git push -u altlinux main
```