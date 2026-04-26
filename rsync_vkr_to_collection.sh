#!/bin/bash
rsync -rvP \
--files-from=<(find ../gh_Altlinux_VKR_2026/ -maxdepth 1 | cut -d '/' -f3) \
VKR/7.Ansible_automation/ \
../gh_Altlinux_VKR_2026/
