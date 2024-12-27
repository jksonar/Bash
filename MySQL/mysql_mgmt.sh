#!/bin/bash

# Default host (can be overridden by environment variable)
MYSQL_HOST=${MYSQL_HOST:-localhost}

# Create user in MySQL/MariaDB.
mysql-create-user() {
  [ -z "$2" ] && { echo "Usage: mysql-create-user (user) (password)"; return; }
  mysql -ve "CREATE USER '$1'@'$MYSQL_HOST' IDENTIFIED BY '$2'"
}

# Delete user from MySQL/MariaDB
mysql-drop-user() {
  [ -z "$1" ] && { echo "Usage: mysql-drop-user (user)"; return; }
  mysql -ve "DROP USER '$1'@'$MYSQL_HOST';"
}

# Create new database in MySQL/MariaDB.
mysql-create-db() {
  [ -z "$1" ] && { echo "Usage: mysql-create-db (db_name)"; return; }
  mysql -ve "CREATE DATABASE IF NOT EXISTS $1"
}

# Drop database in MySQL/MariaDB.
mysql-drop-db() {
  [ -z "$1" ] && { echo "Usage: mysql-drop-db (db_name)"; return; }
  mysql -ve "DROP DATABASE IF EXISTS $1"
}

# Grant all permissions for user for given database.
mysql-grant-db() {
  [ -z "$2" ] && { echo "Usage: mysql-grant-db (user) (database)"; return; }
  mysql -ve "GRANT ALL ON $2.* TO '$1'@'$MYSQL_HOST'"
  mysql -ve "FLUSH PRIVILEGES"
}

# Show current user permissions.
mysql-show-grants() {
  [ -z "$1" ] && { echo "Usage: mysql-show-grants (user)"; return; }
  mysql -ve "SHOW GRANTS FOR '$1'@'$MYSQL_HOST'"
}

# Case statement to handle script arguments
case "$1" in
  create-user)
    shift
    mysql-create-user "$@"
    ;;
  drop-user)
    shift
    mysql-drop-user "$@"
    ;;
  create-db)
    shift
    mysql-create-db "$@"
    ;;
  drop-db)
    shift
    mysql-drop-db "$@"
    ;;
  grant-db)
    shift
    mysql-grant-db "$@"
    ;;
  show-grants)
    shift
    mysql-show-grants "$@"
    ;;
  help)
    echo "Available commands:"
    echo "  create-user (user) (password)   - Create a new MySQL user"
    echo "  drop-user (user)                - Delete an existing MySQL user"
    echo "  create-db (db_name)             - Create a new database"
    echo "  drop-db (db_name)               - Drop an existing database"
    echo "  grant-db (user) (database)      - Grant all permissions on a database to a user"
    echo "  show-grants (user)              - Show grants for a user"
    ;;
  *)
    echo "Usage: $0 {create-user|drop-user|create-db|drop-db|grant-db|show-grants|help}"
    exit 1
    ;;
esac
