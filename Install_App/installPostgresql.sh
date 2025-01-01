#!/bin/bash

OS=""
VERSION=""
PostgreSQLVERSION=""

installDebian() {
    sudo apt update
    sudo apt install -y curl ca-certificates gnupg
    sudo install -d /usr/share/postgresql-common/pgdg
    sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | \
    sudo tee /etc/apt/sources.list.d/pgdg.list
    sudo apt update
    sudo apt -y install postgresql postgresql-contrib
}

installRedhat() {
    case "$VERSION" in
        redhat7)
            sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            sudo yum install -y postgresql${PostgreSQLVERSION}-server postgresql-contrib
            ;;
        redhat8)
            sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            sudo dnf -qy module disable postgresql
            sudo dnf install -y postgresql${PostgreSQLVERSION}-server postgresql-contrib
            ;;
        redhat9)
            sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            sudo dnf -qy module disable postgresql
            sudo dnf install -y postgresql${PostgreSQLVERSION}-server postgresql-contrib
            ;;
        *)
            echo "Unsupported Red Hat version."
            exit 1
            ;;
    esac

    sudo /usr/pgsql-${PostgreSQLVERSION}/bin/postgresql-${PostgreSQLVERSION}-setup initdb
    sudo systemctl enable postgresql-${PostgreSQLVERSION}
    sudo systemctl start postgresql-${PostgreSQLVERSION}
}

usage() {
    echo "Usage: $0 -p <redhat|debian> -v <redhat7|redhat8|redhat9> -d <15|16|17>"
    exit 1
}

# Parse command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -p)
            OS="$2"; shift 2 ;;
        -v)
            VERSION="$2"; shift 2 ;;
        -d)
            PostgreSQLVERSION="$2"; shift 2 ;;
        *)
            usage ;;
    esac
done

if [ -z "$OS" ] || [ "$OS" == "redhat" -a -z "$VERSION" ] || [ -z "$PostgreSQLVERSION" ]; then
    usage
fi

# Install PostgreSQL based on OS
if [ "$OS" == "redhat" ]; then
    installRedhat
elif [ "$OS" == "debian" ]; then
    installDebian
else
    usage
fi
