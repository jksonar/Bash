#!/bin/bash

# File Name For Database 20241225_2257
DATE_FORMAT=$(date +%Y%m%d_%H%M)
# Backup Directory
MYSQLBKP_DIR=/var/backup
RETENTION_DAYS=30
CONNECT_DETAILS=($2)
DB_NAME=$3
LOCKFILE="/tmp/db_backup.lock"

function ACQUIRE_LOCK() {
    if [ -f ${LOCKFILE} ]; then
        echo "[ERROR] Backup script already running. Exiting."
        exit 3
    fi
    touch ${LOCKFILE}
}

function RELEASE_LOCK() {
    rm -f ${LOCKFILE}
}

function VALIDATE_DATA() {
    # Validate my.cnf
    if [ ! -f ~/.my.cnf ]; then
        echo "[ERROR] .my.cnf file is missing in the home directory."
        echo "A .my.cnf file is required for database credentials."
        exit 2
    fi

    # Validate or create backup directory
    if [ ! -d ${MYSQLBKP_DIR} ]; then
        echo "[INFO] Creating backup directory: ${MYSQLBKP_DIR}"
        mkdir -p ${MYSQLBKP_DIR}
    fi
}

function CLEAN_OLD_BACKUPS() {
    echo "[INFO] Removing backups older than ${RETENTION_DAYS} days."
    find ${MYSQLBKP_DIR} -type f -name "*.sql.tar.gz" -mtime +${RETENTION_DAYS} -exec rm -f {} \;
}

function RUN_DB_BACKUP() {
    local CONNECT=$1
    echo "[INFO] Running full database backup for connection: ${CONNECT}"
    cd ${MYSQLBKP_DIR}
    
    ALL_DB=$(mysql --defaults-group-suffix=${CONNECT} -Bse "show databases" | grep -vE "information_schema|mysql|performance_schema|sys")
    for database in ${ALL_DB}; do
        echo "[INFO] Backing up database: ${database}"
        mysqldump --defaults-group-suffix=${CONNECT} ${database} > ${database}_${DATE_FORMAT}.sql
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to dump ${database}"
            continue
        fi
        tar zcf ${database}_${DATE_FORMAT}.sql.tar.gz ${database}_${DATE_FORMAT}.sql
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to compress ${database}_${DATE_FORMAT}.sql"
            continue
        fi
        rm -f ${database}_${DATE_FORMAT}.sql &
    done
    wait
}

function SINGLE_DB_BACKUP() {
    local CONNECT=$1
    local DB=$2
    echo "[INFO] Backing up single database: ${DB} on ${CONNECT}"
    cd ${MYSQLBKP_DIR}
    
    mysqldump --defaults-group-suffix=${CONNECT} ${DB} > ${DB}_${DATE_FORMAT}.sql
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to dump ${DB}"
        return
    fi
    tar zcf ${DB}_${DATE_FORMAT}.sql.tar.gz ${DB}_${DATE_FORMAT}.sql
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to compress ${DB}_${DATE_FORMAT}.sql"
        return
    fi
    rm -f ${DB}_${DATE_FORMAT}.sql
}

function USAGE() {
    echo "Usage: $0 {full|single} <connection_details> <database_name>"
    exit 1
}

### Main Execution ###
if [ $# -lt 2 ]; then
    USAGE
fi

ACQUIRE_LOCK
trap RELEASE_LOCK EXIT

VALIDATE_DATA
CLEAN_OLD_BACKUPS

case "$1" in
    full)
        for CONNECT in "${CONNECT_DETAILS[@]}"; do
            RUN_DB_BACKUP ${CONNECT}
        done
        ;;
    single)
        SINGLE_DB_BACKUP ${CONNECT_DETAILS} ${DB_NAME}
        ;;
    help)
        echo "Available commands:"
        echo "  full (connection_details)                   - Run on MySQL Connection Take ALL Databases"
        echo "  single (connection_details) (database_name) - Delete an existing MySQL user"
        ;;
    *)
        USAGE
        ;;
esac
