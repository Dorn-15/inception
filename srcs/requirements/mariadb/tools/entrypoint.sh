#!/bin/sh
set -e # stop le .sh si code erreur != 0

SQL_PATH="/var/lib/mysql"

#si pas de data init
if [ ! -d ${SQL_PATH}/mysql ]; then
    #init les tables systeme
    mariadb-install-db --user=mysql --ldata=${SQL_PATH} > /dev/null
    # start le serveur en arriere plan et recupere le pid
    mariadbd --user=mysql --skip-networking &
    pid="$!"
    sleep 5

    #def de root et root distant
    mariadb -uroot <<-SQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
        CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
        DELETE FROM mysql.user WHERE User='';
        FLUSH PRIVILEGES;
SQL

    #def de $user avec tous les droits sur la db
    mariadb -uroot -p"${SQL_ROOT_PASSWORD}" <<-SQL
        CREATE DATABASE IF NOT EXISTS \`${SQL_DB}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${SQL_DB}\`.* TO '${SQL_USER}'@'%';
        FLUSH PRIVILEGES;
SQL
    # extinction serveur temporaire et attendre la fin des process
    mysqladmin -uroot -p"${SQL_ROOT_PASSWORD}" shutdown
    wait "$pid" || true
fi

# demarage du serveur final
exec mariadbd --user=mysql --bind-address=0.0.0.0 --port=3306 --skip-networking=0
