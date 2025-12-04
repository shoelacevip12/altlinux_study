# Лабораторная работа 1 «`Механизмы предоставления утилите ping необходимых привилегий`» 
```bash
control ping help
```
```bash
public: Any user can execute ping command
netadmin: Only "netadmin" group members can execute ping command
restricted: Only root can execute ping command
public_caps: Any user can execute ping command (for containers only)
netadmin_caps: Only "netadmin" group members can execute ping command (for containers only)
```
# `Ввиду особенности проработки программы ping в современных linux системах будет описана идея и ожидаемое распределение прав и привилегий`

## Режим: `public`
### Механизм разграничения доступа

```bash
control ping public

ls -ld /usr/libexec/ping
drwx--x--x 2 root netadmin 18 ноя  7 17:42 /usr/libexec/ping

ls -l /usr/libexec/ping/ping
-rwx--s--x 1 root iputils 155432 Jun 25 20:03 /usr/libexec/ping/ping

getent group iputils
iputils:x:949:
```

Право на выполнение имеют все пользователи (бит выполнения `x` для `others`). Установлен бит `SGID` (Set Group ID), что означает, что при запуске файла эффективный идентификатор группы (`EGID`) процесса устанавливается в группу-владельца файла - `iputils` (`GID 949`).

### Получение необходимых привилегий

При запуске процесса с `EGID=949` (группа `iputils`) система проверяет значение настройки ядра` net.ipv4.ping_group_range`. В файле `/lib/sysctl.d/70-iputils.conf` установлено:
```bash
cat /proc/sys/net/ipv4/ping_group_range
949     949

cat /lib/sysctl.d/70-iputils.conf
# Allow ping socket creation for group iputils
net.ipv4.ping_group_range = 949 949
```

Это означает, что процессам, чей эффективный `GID` находится в диапазоне `949-949`, разрешено создавать RAW-сокеты для ICMP пакетов. Таким образом, любой пользователь может выполнять `ping`, так как процесс получает необходимые права через механизм групп.

---

## Режим: `netadmin`
### Механизм разграничения доступа

```bash
control ping netadmin

ls -ld /usr/libexec/ping
drwx--x--- 2 root netadmin 18 ноя  7 17:42 /usr/libexec/ping

ls -l /usr/libexec/ping/ping
-rwx--x--- 1 root netadmin 155432 Jun 25 20:03 /usr/libexec/ping/ping

getent group netadmin
netadmin:x:993:
```

Право на вход каталога `/usr/libexec/ping` имеют только члены группы `netadmin` и `root` пользователь (чтение и выполнение для группы, отсутствие прав для `others`). Бит `SGID` не установлен.
### Получение необходимых привилегий

В настройках ядра устанавливается:
```bash
cat /proc/sys/net/ipv4/ping_group_range
0     0
cat /lib/sysctl.d/70-iputils.conf
# Allow ping socket creation for group iputils
net.ipv4.ping_group_range = 0 0
```

Это отключает использование групп для доступа к RAW-сокетам. Вместо этого используются `Capabilities`. Файлу ping устанавливается `capability`:

```bash
getcap -r /usr/libexec/ping/
/usr/libexec/ping/ping cap_net_raw=ep
```

`Capability` `CAP_NET_RAW` позволяет процессу создавать RAW-сокеты. Только пользователи из группы `netadmin` могут выполнять файл, и при запуске процесс получает необходимые права через унаследованную `capability`.

---

## Режим: `restricted`
### Механизм разграничения доступа

```bash
control ping restricted

ls -ld /usr/libexec/ping
drwx------ 2 root netadmin 18 ноя  7 17:42 /usr/libexec/ping

ls -l /usr/libexec/ping/ping
-rwx------ 1 root root 155432 Jun 25 20:03 /usr/libexec/ping/ping
```

Право на выполнение имеет только `root` (полные права для владельца, отсутствие прав для группы и `others`). Никакие специальные биты (`SUID/SGID`) не установлены.

### Получение необходимых привилегий

Параметр ядра отключает доступ через группы:

```bash
cat /proc/sys/net/ipv4/ping_group_range
0     0
cat /lib/sysctl.d/70-iputils.conf
# Allow ping socket creation for group iputils
net.ipv4.ping_group_range = 0 0
```

Capabilities не устанавливаются. Единственный способ получить необходимые привилегии - запустить `ping` от пользователя root, который по умолчанию имеет все capabilities, включая `CAP_NET_RAW`. Обычные пользователи не могут выполнять `ping`.

---

## Режим: `public_caps`
### Механизм разграничения доступа

```bash
control ping public_caps

ls -ld /usr/libexec/ping
drwx--x--x 2 root netadmin 18 ноя  7 17:42 /usr/libexec/ping

ls -l /usr/libexec/ping/ping
-rwxr-xr-x 1 root root 155432 июн 25 20:03 /usr/libexec/ping/ping
```

Право на выполнение имеют все пользователи (биты выполнения для владельца, группы и `others`). Бит `SGID` не установлен.
### Получение необходимых привилегий

Используются Linux Capabilities:

```bash
getcap -r /usr/libexec/ping/
/usr/libexec/ping/ping cap_net_admin,cap_net_raw=p
```

Capability `CAP_NET_RAW` и `CAP_NET_ADMIN` позволяет процессу создавать RAW-сокеты. В контейнерах обычно не используется разделение через группы из соображений безопасности, поэтому применяется механизм `capabilities`. Любой пользователь в контейнере может выполнять `ping`, и процесс получает необходимые права через унаследованную `capability`.

---

## Режим: `netadmin_caps`
### Механизм разграничения доступа

```bash
control ping netadmin_caps

ls -ld /usr/libexec/ping
drwx--x--- 2 root netadmin 18 ноя  7 17:42 /usr/libexec/ping

ls -l /usr/libexec/ping/ping
-rwx--x--- 1 root netadmin 155432 Jun 25 20:03 /usr/libexec/ping/ping
```

Право на выполнение имеют только члены группы `netadmin` (чтение и выполнение для группы, отсутствие прав для `others`).
### Получение необходимых привилегий

Аналогично режиму `netadmin`, но оптимизировано для контейнеров:

```bash
getcap -r /usr/libexec/ping/
/usr/libexec/ping/ping cap_net_admin,cap_net_raw=p
```

Capability `CAP_NET_RAW` и `CAP_NET_ADMIN` позволяет процессу создавать RAW-сокеты. Только пользователи из группы netadmin и `root` пользователь в контейнере могут выполнять `ping`. Механизм групп в контейнерах используется только для контроля доступа к файлу, а не для получения сетевых привилегий.

---