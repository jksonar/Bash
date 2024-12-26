#!/bin/bash

# File Name For Database 20241225_2257
DATE_FORMATE=$(date +%Y%m%d_%H%M)
# Backup Directory
MYSQLBKP_DIR=/var/backup
# Require For MGMT Multiple Servers
CONNECT_DETAILS="_server1"
CONNECT_DETAILS2="_server2"

DB_NAME="database1"

function VALIDATE_DATA(){
    # exit script if my.cnf not exist 
    if [ ! -f ~/.my.cnf ]
    then
        echo ".my.cnf file is not present in home directory"
        echo "my.cnf file is require for user and password to connect database"
        exit 2
    fi

    if [ ! -d ${MYSQLBKP_DIR} ]
    then
        echo "Creat Backup Directory"
        mkdir -p ${MYSQLBKP_DIR}
    fi
}


function RUN_DB_BACKUP(){
    cd ${MYSQLBKP_DIR}
    # List All Databases Present and ignore default databases
    ALL_DB=$(mysql --defaults-group-suffix=${1} -Bse "show databases" | grep -vE "information_schema|mysql|performance_schema|sys")
    for database in ${ALL_DB}
    do 
    mysqldump --defaults-group-suffix=${1} ${database} > ${database}_${DATE_FORMATE}.sql
    tar zcf ${database}_${DATE_FORMATE}.sql.tar.gz ${database}_${DATE_FORMATE}.sql
    rm -f ${database}_${DATE_FORMATE}.sql
    done
}

function SINGLE_DB_BACKUP(){
    cd ${MYSQLBKP_DIR}
    mysqldump --defaults-group-suffix=${1} ${2} > ${2}_${DATE_FORMATE}.sql
    tar zcf ${2}_${DATE_FORMATE}.sql.tar.gz ${2}_${DATE_FORMATE}.sql
    rm -f ${2}_${DATE_FORMATE}.sql
}

### Function Call ###
VALIDATE_DATA

# RUN_DB_BACKUP ${CONNECT_DETAILS}
# RUN_DB_BACKUP ${CONNECT_DETAILS2}

SINGLE_DB_BACKUP ${CONNECT_DETAILS} ${DB_NAME}
