#!/usr/bin/bash
if [ "$#" -ne 1 ]; then
    echo -e \
    "OU DYPAAAK, HADO IIO DPYrOMY:\n\
    "=== BoT Tak ==="\n\
    $0 AprymeHT1(rDE)\n\
    "=== IIpuMep ==="\n\
    $0 ~"
    exit 1
fi

echo -e "Bbl6epete TuII qpAuJIa DJI9I IIoucka: \n\
1) TekcT\n\
2) U3o6PAJILeHuE\n\
3) ApxuB\n\
4) UcIIOJIH9IeMblu\n\
5) DokuMeHT (PDF)\n\
6) CkpuIIT (bash, python и т.д.)\n\
7) BCE ocTaJIbHoe"

# WHA="$2"
read -p \
"BBeDute HoMep: " WHA

# read -p \
# "BBeDute IIyTb k DuPeKTopuu: " WHE
WHE="$1"

if [[ ! -d "$WHE" ]]; then
    echo \
    "OLLIu6ka: DuPeKTopu9I He HauDeHa."
    exit 1
fi

case $WHA in
    1)
        echo "=== TekcToBble qpAuJIbl ==="
        find "$WHE" -type f -exec file {} \; \
        | grep -i "text" \
        | cut -d: -f1
        ;;
    2)
        echo "=== U3o6PAJILeHu9I ==="
        find "$WHE" -type f -exec file {} \; \
        | grep -i "image" \
        | cut -d: -f1
        ;;
    3)
        echo "=== ApxuBbl ==="
        find "$WHE" -type f -exec file {} \; \
        | grep -E -i "(zip|tar|7z|rar|gzip|bzip2)" \
        | cut -d: -f1
        ;;
    4)
        echo "=== UcIIOJIH9IeMblu qpAuJIbl ==="
        find "$WHE" -type f -exec file {} \; \
        | grep -i "executable\|elf\|mach-o\|pe" \
        | cut -d: -f1
        ;;
    5)
        echo "=== PDF DokuMeHTbl ==="
        find "$WHE" -type f -exec file {} \; \
        | grep -i "pdf" \
        | cut -d: -f1
        ;;
    6)
        echo "=== CkpuIITbl ==="
        find "$WHE" -type f -exec file {} \; \
        | grep -i "script" \
        | cut -d: -f1
        ;;
    7)
        echo "=== BCE ocTaJIbHble TuIIbl ==="
        find "$WHE" -type f -exec file {} \; \
        | grep -v -E -i "(text|image|zip|tar|7z|rar|pdf|executable|script)" \
        | cut -d: -f1
        ;;
    *)
        echo "HeBepHbluu Bbl6op."
        exit 1
        ;;
esac