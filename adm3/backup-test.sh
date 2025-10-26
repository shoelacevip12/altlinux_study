#!/bin/bash

# Скрипт для тестирования backup.sh
# Создает временные каталоги, вызывает backup.sh и проверяет ротацию бэкапов.

# --- Создаем в текущем каталоге два подкаталога: для тестовых файлов и для резервных копий ---
chto_bakapim=$(mktemp -dp .)
if [[ $? -ne 0 ]]; then
    echo "Ошибка: Не удалось создать временный каталог для тестовых файлов."
    exit 1
fi

kuda_bakapim=$(mktemp -dp .)
if [[ $? -ne 0 ]]; then
    echo "Ошибка: Не удалось создать временный каталог для резервных копий."
    rm -rf "$chto_bakapim" # Удаляем первый каталог, если второй не создался
    exit 1
fi
# -----------

# Создаем 5 пустых файлов в каталоге тестовых файлов
touch "$chto_bakapim"/file{1..5}.txt

# Вызываем backup.sh 11 раз
for k in {1..11}; do

    # Предполагаем, что backup.sh находится в той же директории, что и этот скрипт
    ./backup.sh "$chto_bakapim" "$kuda_bakapim"
    if [[ $? -ne 0 ]]; then
        echo "Ошибка: backup.sh завершился с ошибкой на вызове #${k}."
        rm -rf "$chto_bakapim" "$kuda_bakapim"
        exit 1
    fi
    # Задержка, в 1 секунду
    sleep 1
done

# Подсчитываем количество файлов бэкапа в каталоге резервных копий
koli4ectvo=$(find "$kuda_bakapim" -maxdepth 1 -name "backup_*.tar.gz" -type f | wc -l)

echo "Обнаружено резервных копий: $koli4ectvo"

# Проверяем, равно ли количество файлов 10
if [[ $koli4ectvo -eq 10 ]]; then
    echo "ТЕСТ ПРОЙДЕН"
else
    echo "ТЕСТ ПРОВАЛЕН"
fi

# Удаляем временные каталоги
rm -rf "$chto_bakapim" "$kuda_bakapim"
echo "Удалены временные каталоги "$chto_bakapim" "$kuda_bakapim""

echo "Тестовый скрипт завершен."