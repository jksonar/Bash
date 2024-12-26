#!/bin/bash


function RESTORE_FUN(){
    mysql --defaults-group-suffix=${1} -Bse "DROP DATABASE IF EXISTS ${2}"
    mysql --defaults-group-suffix=${1} ${2} < ${3}
}

read -p "Please share connection details" CONNECT_DETAILS
read -p "Please enter database name" DB_NAME
read -p "Please share backup file" DB_FILE

RESTORE_FUN ${CONNECT_DETAILS} ${DB_NAME} ${DB_FILE}