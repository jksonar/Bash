#!/bin/bash

#!/bin/bash

# Create user in MySQL/MariaDB.
mysql-create-user() {
  [ -z "$2" ] && { echo "Usage: mysql-create-user (user) (password)"; return; }
  mysql -ve "CREATE USER '$1'@'%' IDENTIFIED BY '$2'"
}

# Delete user from MySQL/MariaDB
mysql-drop-user() {
  [ -z "$1" ] && { echo "Usage: mysql-drop-user (user)"; return; }
  mysql -ve "DROP USER '$1'@'%';"
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
  mysql -ve "GRANT ALL ON $2.* TO '$1'@'%'"
  mysql -ve "FLUSH PRIVILEGES"
}

# Show current user permissions.
mysql-show-grants() {
  [ -z "$1" ] && { echo "Usage: mysql-show-grants (user)"; return; }
  mysql -ve "SHOW GRANTS FOR '$1'@'%'"
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
  *)
    echo "Usage: $0 {create-user|drop-user|create-db|drop-db|grant-db|show-grants}"
    exit 1
    ;;
esac



# How it Works:

#     The script accepts a command as the first argument (like create-user or drop-db).
#     The shift command removes the first argument, allowing the remaining ones to be passed to the relevant function.
#     If the command isn't recognized, a usage message is displayed.

# ./script.sh create-user user1 password123
# ./script.sh drop-db testdb
# ./script.sh grant-db user1 testdb
