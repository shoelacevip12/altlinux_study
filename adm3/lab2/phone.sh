#!/usr/bin/bash

# ALTSHELL
# Задание 2.1
# Автор скрипта: Скворцов Денис

# Включаем режим: ошибка в любом элементе pipe приведёт к выходу
set -o pipefail 

# Имя файла для хранения записей телефонной книги
DATA_FILE="data.txt" 

# Проверяем, можем ли мы создать/изменить файл данных.
proverk_knigi() {
        touch "$DATA_FILE" || {
        echo -e "Ошибка: Не удалось изменить файл Телефонной книги '$DATA_FILE'.\nПроверьте права доступа." >&2
        exit 100
    }
}

# Выводит справку по использованию скрипта.
show_help() {
    echo -e "Правильное использование:
    
    $0 команда [аргументы]

Доступные команды:
    new    <имя> <номер>    Добавление записи в телефонную книгу
    search <имя-или-номер>  Поиск записей в телефонной книге
    list                    Просмотр всех записей
    delete <имя-или-номер>  Удаление записи
    help или -h             Показ этой справки"
}

# Проверяет корректность ввода имени или номера.
# Принимает тип ввода ("name" или "phone") и значение для проверки.
proverk_vvoda() {
    # Тип проверяемого ввода (name, phone)
    local vvodimyy_type="$1"
    # Значение, которое нужно проверить
    local vvodimo_znach="$2"

    case "$vvodimyy_type" in
        "name")
            # Проверяем имя: только буквы (латиница, кириллица) и пробелы
            [[ "$vvodimo_znach" =~ ^[A-Za-zА-Яа-яЁё\ ]+$ ]] && return 0
            echo -e "Ошибка: Имя содержит недопустимые символы: '$vvodimo_znach'.\n\
            Разрешены только буквы (латиница, кириллица), и пробелы между словами." >&2
            return -1
            ;;
        "phone")
            # Проверяем номер: только цифры, пробелы, (), -, +
            # Сначала удаляем все разрешённые символы
            local otfiltrov_vvod
            otfiltrov_vvod=$(echo "$vvodimo_znach" | sed 's/[[:digit:] ()+-]//g')
            
            # Если после фильтрации ничего не осталось, ввод корректен
            [[ -z "$otfiltrov_vvod" ]] && return 0
            echo -e "Ошибка: Номер телефона содержит недопустимые символы: '$otfiltrov_vvod'.\n\
            Разрешены только цифры, пробелы, круглые скобки , '-' и '+'." >&2
            return -2
            ;;
        *)
            echo "Ошибка: Внутренняя ошибка: Неизвестный тип ввода '$vvodimyy_type' для проверки." >&2
            return -3
            ;;
    esac
}

# Проверяет количество цифр в номере телефона.
proverk_vvoda_telefona() {
    
    # Номер телефона для проверки
    local phone="$1"
    
    # Переменная для хранения количества цифр
    local kolich_cifr
    
    # Удаляем все нецифровые символы и подсчитываем оставшиеся байты
    kolich_cifr=$(echo "$phone" | sed 's/[^[:digit:]]//g' | wc -c)
    kolich_cifr=$((kolich_cifr - 1))

    if [ $kolich_cifr -ne 11 ]; then
        echo "Ошибка: Номер телефона должен содержать 11 цифр (без '+'). Введено: $kolich_cifr." >&2
        return -4
    fi
    echo "$phone"
}

# Экранирует специальные символы в строках.
ekran_spec() {
    echo "$1" | sed 's/[[\.*^$()+?{|]/\\&/g; s/\//\\\//g'
}

# Добавляет новую запись в телефонную книгу.
add_new() {
    
    # Имя для добавления
    local name="$1"
    
    # Номер для добавления
    local phone="$2"

    # Проверяем имя и номер
    proverk_vvoda "name" "$name" || return -1
    proverk_vvoda "phone" "$phone" || return -2
    
    # Проверяем количество цифр в номере
    phone=$(proverk_vvoda_telefona "$phone") || return -2

    # Проверяем доступ к файлу данных
    proverk_knigi

    # Проверяем, не существует ли уже записи с таким номером
    if grep -qF ": $phone$" "$DATA_FILE"; then
        echo -e "Ошибка: Номер телефона '$phone'\n\
        уже существует в телефонной книге." >&2
        return -5
    fi

    # Добавляем запись в файл
    printf '%s : %s\n' "$name" "$phone" >> "$DATA_FILE"
    echo -e "Запись успешно добавлена:\n$name - $phone"
}

# Выводит список всех записей в телефонной книге.
list_zapisey() {
    
    # Проверяем доступ к файлу данных
    proverk_knigi
    
    # Сортируем и выводим содержимое
    if [[ -s "$DATA_FILE" ]]; then
        sort "$DATA_FILE"
    else
        echo "Телефонная книга пуста."
    fi
    exit 0
}

# Ищет записи в телефонной книге по имени или номеру.
poisk_zapisey() {
    
    # Поисковый параметр (имя или номер)
    local poiskovyy_param="$1"
    
    # Проверяем доступ к файлу данных
    proverk_knigi

    # Переменная для хранения найденных строк
    local naydenoe=$(grep -F "$poiskovyy_param" "$DATA_FILE")

    if [ -n "$naydenoe" ]; then
        echo "$naydenoe" | awk -F: '{print $2 " : " $1}'
    else
        echo "Записи не найдены для поискового запроса: $poiskovyy_param" >&2
        exit 1
    fi
}

# Удаляет запись из телефонной книги по имени или номеру.
delete_record() {

    # Параметр, по которому будет производиться удаление (имя или номер)
    local udalenie_po_param="$1"

    # Проверяем доступ к файлу данных
    proverk_knigi

    # Подготовим строку для удаления, экранировав специальные символы
    local filter_udaleniya=$(ekran_spec "$udalenie_po_param")

    # Сохраняем количество строк до удаления
    local sverka_bylo=$(wc -l < "$DATA_FILE" 2>/dev/null || echo 0)

    # Удаляем строки, начинающиеся с "удаляемый_параметр : "
    sed -i "/^$filter_udaleniya : /Id" "$DATA_FILE"
    
    # Удаляем строки, заканчивающиеся на " : удаляемый_параметр"
    sed -i "/ : $filter_udaleniya$/Id" "$DATA_FILE"

    # Сохраняем количество строк после удаления
    local sverka_stalo=$(wc -l < "$DATA_FILE" 2>/dev/null || echo 0)

    # Проверяем, произошло ли удаление
    if [ "$sverka_bylo" -eq "$sverka_stalo" ]; then
        echo "Ошибка: Записей для удаления с запросом '$udalenie_po_param' не найдены." >&2
        exit 1
    else
        echo -e "Запись, содержащая '$udalenie_po_param', успешно удалена."
    fi
}

# Основная функция, обрабатывающая аргументы командной строки и вызывающая соответствующие функции.
main() {
    
    # Команда, переданная в скрипт
    local commanda="$1"

    case "$commanda" in
        "new")
            if [[ $# -ne 3 ]]; then
                echo "Ошибка: Команда 'new' требует ровно 2 аргумента: <имя> <телефон>" >&2
                show_help
                exit 101
            fi
            add_new "$2" "$3"
            ;;
        "search")
            if [[ $# -ne 2 ]]; then
                echo "Ошибка: Команда 'search' требует ровно 1 аргумент: <имя-или-телефон>" >&2
                show_help
                exit 102
            fi
            poisk_zapisey "$2"
            ;;
        "list")
            if [[ $# -ne 1 ]]; then
                echo "Ошибка: Команда 'list' не принимает аргументы." >&2
                show_help
                exit 103
            fi
            list_zapisey
            ;;
        "delete")
            if [[ $# -ne 2 ]]; then
                echo "Ошибка: Команда 'delete' требует ровно 1 аргумент: <имя-или-телефон>" >&2
                show_help
                exit 104
            fi
            delete_record "$2"
            ;;
        "help"|"-h"|"--help")
            show_help
            exit 0
            ;;
        "")
            echo "Ошибка: Команда не указана." >&2
            show_help
            exit 105
            ;;
        *)
            echo "Ошибка: Неизвестная команда: $commanda" >&2
            show_help
            exit 106
            ;;
    esac
}

# Вызов основной функции с аргументами командной строки
main "$@"