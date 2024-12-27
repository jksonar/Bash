#!/bin/bash

# Detect OS and install PHP using Remi repository
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Please install PHP manually."
    exit 1
fi

case $OS in
    ubuntu|debian)
        echo "Installing PHP on Debian/Ubuntu..."
        sudo apt update && sudo apt install -y wget
        sudo echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
        sudo wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
        sudo apt update
        sudo apt install -y php php-cli php-common php-fpm
        ;;
    fedora)
        echo "Installing PHP on Fedora using Remi repository..."
        sudo dnf install -y dnf-utils
        sudo dnf install -y https://rpms.remirepo.net/fedora/remi-release-$(rpm -E %fedora).rpm
        sudo dnf module reset php
        sudo dnf module enable php:remi-8.1
        sudo dnf install -y php php-cli php-common php-fpm
        ;;
    centos|rhel)
        echo "Installing PHP on CentOS/RHEL using Remi repository..."
        sudo yum install -y yum-utils
        sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm 
        sudo yum-config-manager --disable 'remi-php*'
        sudo yum-config-manager --enable remi-php81
        sudo yum install -y php php-cli php-common php-fpm
        ;;
    arch)
        echo "Installing PHP on Arch Linux..."
        sudo pacman -S --noconfirm php
        ;;
    opensuse)
        echo "Installing PHP on openSUSE..."
        sudo zypper install -y php php-cli php-common
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Verify PHP installation
php -v && echo "PHP installed successfully!" || echo "PHP installation failed."
