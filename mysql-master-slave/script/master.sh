#!/bin/bash

MYSQL_ROOT_PASS=Neo@1234
MYSQL_SLAVE_PASS=Neo@1234

SLAVE_IP=
SLAVE_SSH_USER=
SLAVE_SSH_PASS=

# Update Master configuration
echo "Running update master configuration..."
yum install -y sshpass &>/dev/null

cd /opt
mkdir /var/log/mysql
touch /var/log/mysql/mysql-bin.log
chown -R mysql:mysql /var/log/mysql

cat >/etc/my.cnf <<EOF
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.7/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
# log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

# General Settings
bind-address=0.0.0.0
collation-server=utf8_unicode_ci
init-connect='SET NAMES utf8'
character-set-server=utf8
slow_query_log=1
long_query_time=2
general_log=0
slow_query_log_file=/var/log/mysql/slow.log

# InnoDB Settings
max_connections=5000
# Typical values are 5-6GB (8GB RAM)
innodb_buffer_pool_size=6G
innodb_log_file_size=4G
innodb_flush_log_at_trx_commit=1

# Query Cache
query_cache_type=0

# Replication Settings - Master
server-id=1
log_bin=/var/log/mysql/mysql-bin.log
EOF

service mysqld restart
service mysqld status

# CREATE SLAVE USER
echo "....................................................................."
echo "Creating SLAVE USER"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "\
SHOW DATABASES; \
SHOW MASTER STATUS; \
"

mysql -u root -p"$MYSQL_ROOT_PASS" -e "\
CREATE USER 'slave'@'$SLAVE_IP' IDENTIFIED BY '$MYSQL_SLAVE_PASS'; \
GRANT REPLICATION SLAVE ON *.* TO 'slave'@'$SLAVE_IP'; \
FLUSH PRIVILEGES; \
"

echo "....................................................................."
echo "Next, turn on the lock on your databases to prevent the change in data."

# LOCK DATABASE AND BACKUP
mysql -u root -p"$MYSQL_ROOT_PASS" -e "\
FLUSH TABLES WITH READ LOCK; \
"

# Dump one database
# mysqldump -u root -p"$MYSQL_ROOT_PASS" $DB_BACKUP --master-data | gzip -9 > /opt/master-data.sql.gz

# Dump all databases
mysqldump -u root -p"$MYSQL_ROOT_PASS" --all-databases --master-data | gzip -9 >/opt/master-data.sql.gz

# Copy backupfile to Slave database
echo "....................................................................."
echo "Copying backupfile to SLAVE server..."

sshpass -p "$SLAVE_SSH_PASS" scp -r /opt/master-data.sql.gz $SLAVE_SSH_USER@$SLAVE_IP:/tmp

# Using ssh key
# scp -r /opt/master-data.sql.gz your_alias_server:/tmp

echo "Done"
