#!/usr/bin/bash
IIpuBeT() {
    local D=$(date '+%d-%m-%Y %H:%M')
    echo -e "Добро пожаловать на компьютер $HOSTNAME, $USER\n\
    Ваш домашний каталог $HOME\n\
    Ваш командный интерпретатор $BASH\n\
    Сейчас на компьютере выставлена дата $D"
}
IIpuBeT