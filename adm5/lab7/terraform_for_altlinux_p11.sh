#!/bin/bash -x

# CREATED:
# vitaliy.natarov@yahoo.com
# Unix/Linux blog:
# http://linux-notes.org
# Vitaliy Natarov

# RECREATED:
# ArtamonovKA
# For AltLinux

# MODED:
# 17.12.25
# Shoelacevip12
# For AltLinux p11 workstation

function install_terraform () {
        #
        if [ -f /etc/altlinux-release ] || [ -f /etc/redhat-release ] ; then
                #update OS
                apt-get update &> /dev/null -y && apt-get dist-upgrade &> /dev/null -y
                #
                if ! type -path "wget" > /dev/null 2>&1; then apt-get install wget &> /dev/null -y; fi
                if ! type -path "curl" > /dev/null 2>&1; then apt-get install curl &> /dev/null -y; fi
                if ! type -path "unzip" > /dev/null 2>&1; then apt-get install unzip &> /dev/null -y; fi
        OS=$(lsb_release -ds|cut -d '"' -f2|awk '{print $1}')
        OS_MAJOR_VERSION=$(sed -rn 's/.*([0-9]).[0-9].*/\1/p' /etc/redhat-release)
                OS_MINOR_VERSION=$(cat /etc/redhat-release | cut -d"." -f2| cut -d " " -f1)
                Bit_OS=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
                echo "$OS-$OS_MAJOR_VERSION.$OS_MINOR_VERSION with $Bit_OS bit arch"
                #
                site="https://hashicorp-releases.yandexcloud.net/terraform/"
        Latest_terraform_version=$(curl -s "$site" --list-only | grep -E "terraform_" | grep -Ev "beta|alpha" | head -n1| cut -d ">" -f2| cut -d "<" -f1 | cut -d"_" -f2)
        URL_with_latest_terraform_package=$site$Latest_terraform_version
                #
                if [ "`uname -m`" == "x86_64" ]; then
                        Latest_terraform_package=$(curl -s "$URL_with_latest_terraform_package/" --list-only |grep -E "terraform_" | grep -E "linux_amd64"|cut -d ">" -f2| cut -d "<" -f1)
                        Current_link_to_archive=$URL_with_latest_terraform_package/$Latest_terraform_package
                elif [ "`uname -m`" == "i386|i686" ]; then
                        Latest_terraform_package=$(curl -s "$URL_with_latest_terraform_package/" --list-only |grep -E "terraform_" | grep -Ev "(SHA256SUMS|windows)"| grep -E "linux_386"|cut -d ">" -f2| cut -d "<" -f1)
                        Current_link_to_archive=$URL_with_latest_terraform_package/$Latest_terraform_package
                fi
                echo $Current_link_to_archive
                mkdir -p /usr/local/src/ && cd /usr/local/src/ && wget $Current_link_to_archive &> /dev/null
                unzip -o $Latest_terraform_package
                rm -rf /usr/local/src/$Latest_terraform_package*
                yes|mv -f /usr/local/src/terraform /usr/local/bin/terraform
                chmod +x /usr/local/bin/terraform
        else
        OS=$(uname -s)
        VER=$(uname -r)
        echo 'OS=' $OS 'VER=' $VER
        fi
}
install_terraform
echo "========================================================================================================";
echo "================================================FINISHED================================================";
echo "========================================================================================================";
terraform -version