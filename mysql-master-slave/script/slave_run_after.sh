#!/bin/bash

MYSQL_NEW_USER=neomysql
MYSQL_NEW_USER_PASS=Neo@1234

MASTER_HOST=
# this value from Master Position.
MASTER_LOG_POS=
MASTER_LOG_FILE=
MYSQL_SLAVE_PASS=Neo@1234

echo "Running..."

# Need a file dump
cd /opt
mv /tmp/master-data.sql.gz /opt

mysql -u"$MYSQL_NEW_USER" -p"$MYSQL_NEW_USER_PASS" -e "\
STOP SLAVE; \
"

gunzip </opt/master-data.sql.gz | mysql -u"$MYSQL_NEW_USER" -p"$MYSQL_NEW_USER_PASS"

mysql -u"$MYSQL_NEW_USER" -p"$MYSQL_NEW_USER_PASS" -e "\
SHOW MASTER STATUS; \
SHOW DATABASES; \
STOP SLAVE; \
CHANGE MASTER TO MASTER_HOST='$MASTER_HOST', MASTER_USER='slave', MASTER_PASSWORD='$MYSQL_SLAVE_PASS', MASTER_LOG_FILE='$MASTER_LOG_FILE', MASTER_LOG_POS=$MASTER_LOG_POS; \
START SLAVE; \
SHOW SLAVE STATUS\G; \
"

echo "Done"
