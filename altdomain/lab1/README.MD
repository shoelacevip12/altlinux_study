# Лабораторная работа 8 «`Установка Альт Домен`» 
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
id_alt-domain_2026_host_ed25519                                                                                                                               100%  411    32.5KB/s   00:00    
id_alt-domain_2026_host_ed25519.pub  
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