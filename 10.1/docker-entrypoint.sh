#!/usr/bin/env sh

MYSQL_DATA_DIR=/var/lib/mysql
mkdir -p "$MYSQL_DATA_DIR"

# random password generator
randpw() {
    tr -dc _A-Za-z0-9 < /dev/urandom | head -c${1:-12};echo;
}

if [ "$1" = mysqld -o "$1" = mysqld_safe ] && [ ! "$(ls -1 $MYSQL_DATA_DIR)" ]; then
    mysql_install_db --user=mysql --datadir="$MYSQL_DATA_DIR"

    if [ ! "$MYSQL_ENV_FILE" ]; then
        MYSQL_ENV_FILE=/dev/null
    else
        mkdir -p "$(dirname $MYSQL_ENV_FILE)"
    fi

    # the default owner is root
    chown -R mysql:mysql "$MYSQL_DATA_DIR"

    # wait until mysql is running
    mysqld_safe --datadir="$MYSQL_DATA_DIR" >/dev/null &
    mysqladmin --silent --wait=30 ping >/dev/null

    : ${MYSQL_ROOT_PASSWORD:=$(randpw)}
    echo "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" >> "$MYSQL_ENV_FILE"

    # initialize users and remove test database
    mysql -uroot -e \
          "DELETE FROM mysql.user;\
          CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;\
          GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;\
          DROP DATABASE IF EXISTS test ;\
          "

    if [ "$MYSQL_USER" ]; then
        : ${MYSQL_PASSWORD:=$(randpw)}
        mysql -uroot -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;"
        echo "MYSQL_USER=${MYSQL_USER}" >> "$MYSQL_ENV_FILE"
        echo "MYSQL_PASSWORD=${MYSQL_PASSWORD}" >> "$MYSQL_ENV_FILE"

        # maybe need initialize a new database for the user
        if [ "$MYSQL_DATABASE" ]; then
            mysql -uroot -e "CREATE DATABASE \`$MYSQL_DATABASE\` DEFAULT CHARSET UTF8 COLLATE UTF8_GENERAL_CI ;"
            mysql -uroot -e "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;"
            echo "MYSQL_DATABASE=${MYSQL_DATABASE}" >> "$MYSQL_ENV_FILE"
        fi
    fi

    mysql -uroot -e 'FLUSH PRIVILEGES ;'
    mysqladmin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown

    echo
    echo "=================================================================="
	echo "MySQL initialization finished."
    echo "------------------------------------------------------------------"
    echo "Initialization environments:"
    echo
    set | grep '^MYSQL_' | grep -vE 'ENV_FILE|DATA_DIR'

    [ "$MYSQL_ENV_FILE" != /dev/null ] && {
        echo
        echo "The environment variables have been save to ${MYSQL_ENV_FILE}"
    }
    echo "=================================================================="
    echo
fi

chown -R mysql:mysql "$MYSQL_DATA_DIR"
exec "$@"
