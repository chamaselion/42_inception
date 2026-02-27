#!/bin/bash
set -e

MARIADB_PORT="${MARIADB_PORT:-3306}"

# Ensure dirs exist and correct ownership before starting mariadbd
mkdir -p /etc/mysql/mariadb.conf.d /etc/my.cnf.d /run/mysqld /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql /run/mysqld 2>/dev/null || true
chmod 750 /var/lib/mysql 2>/dev/null || true

# If Debian-style config exists, create a symlink for any software expecting /etc/my.cnf.d/mariadb-server.cnf
if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ] && [ ! -e /etc/my.cnf.d/mariadb-server.cnf ]; then
    ln -s /etc/mysql/mariadb.conf.d/50-server.cnf /etc/my.cnf.d/mariadb-server.cnf || true
fi

# Ensure MariaDB is reachable from other containers on the Docker network
for conf in /etc/mysql/mariadb.conf.d/50-server.cnf /etc/my.cnf.d/mariadb-server.cnf; do
    [ -f "$conf" ] || continue
    sed -i -E 's@^bind-address\s*=.*@bind-address = 0.0.0.0@' "$conf" || true
    if grep -Eq '^skip-networking' "$conf"; then
        sed -i -E 's@^skip-networking.*@# skip-networking@' "$conf" || true
    fi
done

# Initialize on first mount
if [ ! -e /var/lib/mysql/.firstmount ]; then
    # Ensure ownership for initialization
    chown -R mysql:mysql /var/lib/mysql /run/mysqld 2>/dev/null || true

    # Initialize DB files if not present
    if ! mysql_install_db --datadir=/var/lib/mysql --user=mysql --skip-test-db >/dev/null 2>&1; then
        mariadb-install-db --datadir=/var/lib/mysql --user=mysql --skip-test-db >/dev/null 2>&1 || true
    fi

    # Build first-mount SQL and run bootstrap init without background daemon
    BOOTSTRAP_SQL_FILE="/var/lib/mysql/bootstrap-init.sql"
    if [ -f /docker-entrypoint-initdb.d/init.sql ]; then
        envsubst < /docker-entrypoint-initdb.d/init.sql > "$BOOTSTRAP_SQL_FILE"
    else
        MYSQL_DATABASE="${MYSQL_DATABASE:-}"
        MYSQL_USER="${MYSQL_USER:-}"
        MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
        MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"

        cat << EOF > "$BOOTSTRAP_SQL_FILE"
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
    fi

    chmod 600 "$BOOTSTRAP_SQL_FILE"
    chown mysql:mysql "$BOOTSTRAP_SQL_FILE" 2>/dev/null || true
    mariadbd --bootstrap --datadir=/var/lib/mysql --user=mysql < "$BOOTSTRAP_SQL_FILE" || true
    rm -f "$BOOTSTRAP_SQL_FILE"

    touch /var/lib/mysql/.firstmount
fi

# Final ownership fix before exec
chown -R mysql:mysql /var/lib/mysql /run/mysqld 2>/dev/null || true

MYSQL_DATABASE="${MYSQL_DATABASE:-wordpress}"
MYSQL_USER="${MYSQL_USER:-wpuser}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-wppass}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootpass}"

RUNTIME_INIT_FILE="/var/lib/mysql/runtime-init.sql"
cat << EOF > "$RUNTIME_INIT_FILE"
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
ALTER USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
chmod 600 "$RUNTIME_INIT_FILE"
chown mysql:mysql "$RUNTIME_INIT_FILE" 2>/dev/null || true

# Exec main server
exec mariadbd --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock --user=mysql --port="$MARIADB_PORT" --init-file="$RUNTIME_INIT_FILE"