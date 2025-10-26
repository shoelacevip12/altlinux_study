#!/bin/bash
systemctl restart rsyslog crond sshd

echo "ТЕСТ_ПРИОРИТЕОВ_СООБЩЕНИЙ"

LEVELS=("info" "notice" "warn" "err" "crit" "alert" "emerg" "debug" "debug" "debug")

# Перебор уровней
for LEVEL in "${LEVELS[@]}"; do
    logger -p local4."$LEVEL" \
    "level_"$LEVEL"_SKV_DV" \
     && sleep 1 \
     && date \
     && echo "$LEVEL"
done
