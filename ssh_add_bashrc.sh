#!/bin/bash

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval $(ssh-agent)
fi

if [ -n "$SSH_AUTH_SOCK" ]; then
    for key in ~/.ssh/id_skv_VKR_vpn ~/.ssh/id_gitflic_2026_ed25519 ~/.ssh/id_github_2026_ed25519; do
        if [ -f "$key" ]; then
            # Извлекаем комментарий ключа и проверяем, есть ли он в агенте
            comment=$(ssh-keygen -l -f "$key" | awk '{print $3}')
            if ! ssh-add -L | grep -q "$comment"; then
                ssh-add "$key"
            fi
        fi
    done
fi
