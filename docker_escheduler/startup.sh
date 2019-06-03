#! /bin/bash
set -e

MYSQL_ROOT_PWD="root@123"
MYSQL_USER="escheduler"
MYSQL_USER_PWD="escheduler"
MYSQL_USER_DB="escheduler"

echo "[i] Setting up new power user credentials."
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
find /var/lib/mysql -type f -exec touch {} \; && service mysql start $ sleep 10

echo "[i] Setting root new password."
mysql --user=root --password=root -e "UPDATE mysql.user set authentication_string=password('$MYSQL_ROOT_PWD') where user='root'; FLUSH PRIVILEGES;"

echo "[i] Setting root remote password."
mysql --user=root --password=$MYSQL_ROOT_PWD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PWD' WITH GRANT OPTION; FLUSH PRIVILEGES;"

if [ -n "$MYSQL_USER_DB" ]; then
        echo "[i] Creating datebase: $MYSQL_USER_DB"
        mysql --user=root --password=$MYSQL_ROOT_PWD -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_USER_DB\` CHARACTER SET utf8 COLLATE utf8_general_ci; FLUSH PRIVILEGES;"
        if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_USER_PWD" ]; then
                echo "[i] Create new User: $MYSQL_USER with password $MYSQL_USER_PWD for new database $MYSQL_USER_DB."
        else
                echo "[i] Don\`t need to create new User."
        fi
else
        if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_USER_PWD" ]; then
                echo "[i] Create new User: $MYSQL_USER with password $MYSQL_USER_PWD for all database."
                mysql --user=root --password=$MYSQL_ROOT_PWD -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
        else
                echo "[i] Don\`t need to create new User."
        fi
fi

#killall mysqld
sleep 5
echo "[i] Setting end,have fun."


/usr/bin/mysqld_safe &

echo "导入mysql数据"
nohup /opt/escheduler/script/create_escheduler.sh &

echo "启动zk"
nohup /opt/zookeeper/bin/zkServer.sh start &

echo "启动api-server"
nohup /opt/escheduler/bin/escheduler-daemon.sh start api-server &

echo "启动master-server"
nohup /opt/escheduler/bin/escheduler-daemon.sh start master-server &

echo "启动worker-server"
nohup /opt/escheduler/bin/escheduler-daemon.sh start worker-server &

echo "启动logger-server"
nohup /opt/escheduler/bin/escheduler-daemon.sh start logger-server &

echo "启动alert-server"
nohup /opt/escheduler/bin/escheduler-daemon.sh start alert-server &

echo "启动nginx"
nginx &

while true
do
 	sleep 100
done
exec "$@"
