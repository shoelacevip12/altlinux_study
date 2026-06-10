# Лабораторная работа 1 «`Установка Альт Домен`» 

![](../alt_domain.png)

## Памятка входа
```bash
# вход на bastion хост по ключу по ssh
eval $(ssh-agent) \
&& ssh-add \
~/.ssh/id_alt-domain_2026_host_ed25519

> ~/.ssh/known_hosts \
&& ssh -t -o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"su -"
```
### SSH обмен ключами (проброс ключа до altsrv1 через altwks1)
```bash
# Копируем пару ключей на промежуточный хост altwks1
> ~/.ssh/known_hosts \
&& scp \
~/.ssh/id_alt-domain_2026_host_ed25519{,.pub} \
sysadmin@172.16.100.2:~/.ssh/

# Передаем публичный ключ на altsrv1
ssh -t -o StrictHostKeyChecking=accept-new \
sysadmin@172.16.100.2 \
"ssh-copy-id \
-o StrictHostKeyChecking=accept-new \
-i ~/.ssh/id_alt-domain_2026_host_ed25519.pub \
sysadmin@192.168.100.11"
```

<details>
<summary>Логи передачи файлов</summary>

```log
Agent pid 16341
Identity added: /home/shoel/.ssh/id_alt-domain_2026_host_ed25519 (cours_alt-domain)
```

```log
The authenticity of host '172.16.100.2 (172.16.100.2)' can't be established.
ED25519 key fingerprint is: SHA256:cHzpYMC7ONqD/C8zAWz/WJUD+byrCOvm9Ir7DOvEspM
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '172.16.100.2' (ED25519) to the list of known hosts.
id_alt-domain_2026_host_ed25519                  100%  411    32.5KB/s   00:00    
id_alt-domain_2026_host_ed25519.pub              100%   98     7.5KB/s   00:00
```

```log
/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/sysadmin/.ssh/id_alt-domain_2026_host_ed25519.pub"
/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
sysadmin@192.168.100.11's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -o 'StrictHostKeyChecking=accept-new' 'sysadmin@192.168.100.11'"
and check to make sure that only the key(s) you wanted were added.

Connection to 172.16.100.2 closed.
```

</details>

### Проверка входа
```bash
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
"hostnamectl && ip -br a"
```

<details>
<summary>вывод доступа до altsrv1</summary>

```log
 Static hostname: altsrv1
       Icon name: computer-vm
         Chassis: vm 🖴
      Machine ID: dac3b001c8db895abaedef1a683ecf35
         Boot ID: bc37f52a2d9b4f00af087cec56ca1c69
  Virtualization: kvm
Operating System: ALT Server 11.1 (Mendelevium)
     CPE OS Name: cpe:/o:alt:server:11.1
          Kernel: Linux 6.12.27-6.12-alt1
    Architecture: x86-64
 Hardware Vendor: QEMU
  Hardware Model: Standard PC _i440FX + PIIX, 1996_
Firmware Version: 1.16.3-alt3
   Firmware Date: Tue 2014-04-01
    Firmware Age: 12y 2month 1w 2d                 
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens19            UP             192.168.100.11/24 fe80::9c6e:f5ff:fe1f:c9e7/64 
Connection to 192.168.100.11 closed.
```

</details>

## Работа по развертыванию домена
```bash
ssh -t \
-i ~/.ssh/id_alt-domain_2026_host_ed25519 \
-J sysadmin@172.16.100.2 \
-o StrictHostKeyChecking=accept-new \
sysadmin@192.168.100.11 \
"su -"
```
### Смена имени под fqdn
```bash
hostnamectl \
set-hostname \
altsrv1.den.skv
```

### Устанавливаем имя NIS-домена
```bash
domainname den.skv
```