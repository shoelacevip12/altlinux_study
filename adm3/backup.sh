#!/usr/bin/bash

# Скрипт резервного копирования
# Назначение: создает резервные копии каталога с ротацией до 10 архивов
# Скворцов Денис

# Функция вывода справки
show_help() {
    echo -e "Использование: backup.sh [КАТАЛОГ_ДЛЯ_КОПИРОВАНИЯ] [КАТАЛОГ_ХРАНЕНИЯ_КОПИЙ]
  --help          Показать это справочное сообщение

Примеры:
  ./backup.sh /home/usr /storage/backups
  ./backup.sh . /storage/backups
  ./backup.sh --help"
}

# Проверяем, переданы ли оба аргумента
if [ "$1" = "--help" ]; then
    show_help
    exit 0
elif [ "$#" -ne 2 ]; then
    show_help
    exit 100
fi

# Допускаются переменные путей в символьном или в абсолютном виде
chto_bakapim="$1"
kuda_bakapim="$2"


# Параметризация имён бэкапов
vremya=$(date +"%d%m%Y_%H%M%S")
imya_bakapa="backup_$vremya"
put_bakapa="$kuda_bakapim/$imya_bakapa"

# Максимально Допустимое количество бэкапов
max_koli4ectvo=10

# Функция проверки аргументов
IIpoBepKa() {
    
    # Преобразование переменных символьных путей в абсолютные командой realpath
    chto_bakapim=$(realpath "$chto_bakapim")
    kuda_bakapim=$(realpath "$kuda_bakapim")

    # Проверяем существование исходного каталога с помощью утилиты test
    if [[ ! -d "$chto_bakapim" ]]; then
        echo "Ошибка: Каталог для резервного копирования '$chto_bakapim' не существует."
        exit 101
    fi

    # Проверяем, является ли dest каталогом src
    if [[ "$chto_bakapim" == "$kuda_bakapim" ]]; then
        echo "Ошибка: Каталог хранения резервных копий '$kuda_bakapim' не может быть каталогом бэкапа '$chto_bakapim'."
        exit 102
    fi

    # Экранируем специальные символы в пути для использования в регулярном выражении
    local chto_bakapim_reg_ex=$(sed 's/[[\.*^$()+?{|]/\\&/g' <<< "$chto_bakapim")

    # Проверяем, начинается ли путь хранения резервных копий с путём бэкапируемого места
    if [[ "$kuda_bakapim" =~ ^${chto_bakapim_reg_ex}/([^/].*)?$ ]]; then
        echo "Ошибка: Каталог хранения резервных копий '$kuda_bakapim' не может быть подкаталогом бэкапируемого пути '$chto_bakapim'."
        exit 103
    fi

    # Предотвращаем бэкап внутрь самого бэкапируемого места
    local kuda_bakapim_reg_ex=$(sed 's/[[\.*^$()+?{|]/\\&/g' <<< "$kuda_bakapim")

    if [[ "$chto_bakapim" =~ ^${kuda_bakapim_reg_ex}/([^/].*)?$ ]]; then
        echo "Ошибка: бэкапируемый Каталог'$chto_bakapim' не может быть подкаталогом хранения резервных копий '$kuda_bakapim'."
        exit 104
    fi

    return 0
}

# Функция выполнения резервного копирования
IIpoLLeDypA_63KaPa() {

    # Пытаемся создать каталог назначения, если он не существует
    mkdir -p "$kuda_bakapim" 2>/dev/null

    # Проверяем права на запись в каталог назначения с помощью утилиты test
    if ! test -w "$kuda_bakapim"; then
        echo "Ошибка: Нет прав на запись в каталог '$kuda_bakapim'."
        exit 105
    fi

    # Создаем архив tar
    # с указанием каталога, в который нужно перейти перед выполнением (-C "$(dirname...)" )
    # и извлечением имени последнего элемента пути из абсолютного пути  (-C ... "$(basename ...)")
    if tar -czf "$put_bakapa.tar.gz" \
    -C "$(dirname "$chto_bakapim")" \
    "$(basename "$chto_bakapim")"; then
        echo "Резервная копия создана: $put_bakapa.tar.gz"
    else
        echo "Ошибка: Не удалось создать резервную копию '$put_bakapa.tar.gz'."
        exit 106
    fi
}

# Функция ротации резервных копий
RoTaLLu9I_BAK() {
    
    # Переменная получения списока бэкапов c обратной отсортировкой по времени
    local BAKAIIbl=$(find "$kuda_bakapim" 
    -name "backup_*.tar.gz" \
    -type f \
    -printf "%T@ %p\n" \
    2>/dev/null \
    | sort -nr)

    # Переменная получения текущего количества бэкапов
    local koli4ectvo=$(echo "$BAKAIIbl" \
    | grep -c "^")

    # Ищем старые бэкапы и удаляем если их количество превышает $max_koli4ectvo
    while [ "$koli4ectvo" -ge $max_koli4ectvo ]; do
        
        echo "$BAKAIIbl" \
        | sed '1,11d' \
        | xargs rm -rf

        # Обновляем значения для цикла поиска и удаления старых бэкапов
        BAKAIIbl=$(echo "$BAKAIIbl" | tail -n +2)
        koli4ectvo=$((koli4ectvo - 1))
    done
}

# Основная логика скрипта
main() {
            IIpoBepKa $chto_bakapim $kuda_bakapim
            IIpoLLeDypA_63KaPa || exit 107
            RoTaLLu9I_BAK
}

main "$@"