# Набор удачных команд для Лабораторной работы 4

### Оформление лабараторной работы и подготовка подключения
```bash
mkdir -p ~/altlinux/adm \
&& cd ~/altlinux/adm

git init

git config --global user.email "shoelacevip21@gmail.com"

git config --global user.name "shoelacevip12"

git config --global --add safe.directory .

git log --oneline

git remote add altlinux https://github.com/shoelacevip12/altlinux_study.git

git pull altlinux main

git branch -M main

mkdir adm3 \
&& cd !$

touch alt_adm3_lab4_commands.md

mkdir lab4 \
&& cd !$ \
&& mkdir img \
&& touch README.MD

sudo bash -c "virsh net-start --network vagrant-libvirt \
&& virsh start altlinux_altlinux_install \
&& virsh start altlinux_empty_vm

git status

git add .. .

git log --oneline

git commit -am "Обновление_для_след_модул_обучения"

git status

git push -u altlinux main
```
#### После оформения
##### Подготовка Управляемого и Управляющего узлов
```bash
ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm admin@192.168.121.2

su -

ssh-keygen -t ed25519 \
-f ~/.ssh/id_xrdp_host \
-C "xrdp_host-access-key"

ssh-copy-id -i ~/.ssh/id_xrdp_host.pub \
sadmin@192.168.121.4

ssh -i ~/.ssh/id_xrdp_host \
sadmin@192.168.121.4 \
"hostname"

cp ~/.ssh/id_xrdp_host* \
/home/admin/.ssh/ \
&& chown admin:admin \
/home/admin/.ssh/id_xrdp_host*

ping -c 3 ya.ru

apt-get update \
&& update-kernel -y \
&& apt-get dist-upgrade -y \
&& apt-get install ansible sshpass -y \
&& apt-get autoremove -y \
&& systemctl reboot


ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm sadmin@192.168.121.4

su -

cat /home/sadmin/.ssh/authorized_keys \
>> ~/.ssh/authorized_keys

ping -c 3 ya.ru

apt-get update \
&& apt-get install \
python3 \
python3-module-yaml \
python3-module-jinja2 \
python3-module-json5 -y \
&& systemctl reboot
```
##### Выполнение работы
```bash
ssh -o "ProxyCommand=ssh -i ~/.ssh/id_kvm_host -W %h:%p shoel@shoellin" \
-i ~/.ssh/id_vm admin@192.168.121.2

mkdir ans \
&& cd !$

ansible-config init --disabled -t all > ansible.cfg

eval $(ssh-agent) \
&& ssh-add ~/.ssh/id_xrdp_host

sed -ie 's|;ssh_agent=.*|ssh_agent=auto|' ansible.cfg  \
&& grep "ssh_agent=" ansible.cfg


sed -ie 's|;home=~/.ansible|home=~/ans|' ansible.cfg \
&& grep "home=~/" ansible.cfg

sed -ie 's|;inventory=\[.*\]|inventory=./hosts.ini|' ansible.cfg \
&& grep "inventory=" ansible.cfg

touch hosts.ini

mkdir roles

sed -ie 's|;roles_path=\/.*|roles_path=~/ans/roles|' ansible.cfg \
&& grep "roles_path=" ansible.cfg

sed -ie 's|;host_key_checking.*|host_key_checking=False|' ansible.cfg \
&& grep "host_key_checking=" ansible.cfg

ansible-galaxy init roles/xrdp_skv

cat >  ~/ans/hosts.ini << 'EOF'
[alt_work_p11]
192.168.121.[4:6]

[alt_work_p11:vars]
ansible_user=sadmin
ansible_ssh_private_key_file=~/.ssh/id_xrdp_host
ansible_python_interpreter=/usr/bin/python3
EOF

cat > ~/ans/roles/xrdp_skv/tasks/main.yml << 'EOF'
---
- name: Обновление пакетов
  apt_rpm:
    update_cache: true
    dist_upgrade: true
    # update_kernel: true

- name: Установка xrdp
  apt_rpm:
    name: 
      - xrdp
    state: present
    clean: true

- name: Запуск и включение сервисов xrdp
  systemd:
    name: "{{ item }}"
    state: started
    enabled: yes
  loop:
    - xrdp
    - xrdp-sesman
  register: result_services

- name: Вывод состояния сервисов в сервисах
  debug:
    msg: "{{ result_services.stdout }}"
EOF

cat > ~/ans/role_xrdp.yaml<< 'EOF'
---
- name: Установки RDP-сервера в ОС Альт
  hosts: alt_work_p11
  become: yes
  become_method: su
  become_user: root
  gather_facts: yes

  vars_prompt:
    - name: "sudo_password"
      prompt: "Введите пароль для su (пользователя sadmin)"
      private: yes

  # Устанавливаем переменную 'ansible_become_password' с помощью 'vars'
  vars:
    ansible_become_password: "{{ sudo_password }}"

  tasks:
    - name: Запуск роли xrdp_skv
      include_role:
        name: xrdp_skv
      no_log: true
EOF

exit



rsync \
-e "ssh -i ~/.ssh/id_vm" \
-P admin@192.168.121.2:~/ans/* .

cd ~/altlinux/adm/adm3/lab4

git status

git add . .. ../.. \
&& git status

git log --oneline

git commit -am "для 4-ей лабы_adm4_1" \
&& git push -u altlinux main
```
###
```bash

```
