#!/bin/bash

MYSQL_NEW_ROOT_PASS=Neo@1234
MYSQL_NEW_USER=neomysql
MYSQL_NEW_USER_PASS=Neo@1234
# Empty this variable to sync all databases
DB_NAME_TO_SYNC=

# INSTALL mysqld
echo "Running install mysql v5.7 ..."
cd /opt
# sudo yum -y update &> /dev/null
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 &>/dev/null
sudo yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm &>/dev/null
sudo yum -y install mysql-community-server &>/dev/null
sudo systemctl start mysqld
sudo systemctl status mysqld
sudo systemctl enable mysqld

# get temporary root password
root_temp_pass=$(sudo grep 'A temporary password' /var/log/mysqld.log | tail -1 | awk '{split($0,a,": "); print a[2]}')
echo "root_temp_pass: " $root_temp_pass

# mysql_secure_installation.sql
sudo cat >mysql_secure_installation.sql <<EOF
# Make sure that NOBODY can access the server without a password
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_NEW_ROOT_PASS';

# Kill the anonymous users
DELETE FROM mysql.user WHERE User='';

# disallow remote login for root
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

# Kill off the demo database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

# Make our changes take effect
FLUSH PRIVILEGES;
EOF

mysql -uroot -p"$root_temp_pass" --connect-expired-password </opt/mysql_secure_installation.sql

# Create new user
echo "....................................................................."
echo "Creating new user..."

mysql -uroot -p"$MYSQL_NEW_ROOT_PASS" -e "SHOW DATABASES;"
mysql -uroot -p"$MYSQL_NEW_ROOT_PASS" -e "\
CREATE USER '$MYSQL_NEW_USER'@'%' IDENTIFIED BY '$MYSQL_NEW_USER_PASS'; \
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_NEW_USER'@'%'; \
SHOW GRANTS FOR $MYSQL_NEW_USER; \
FLUSH PRIVILEGES;
"

# Update Slave configuration
echo "....................................................................."
echo "Running update slave configuration..."
mkdir /var/log/mysql
touch /var/log/mysql/mysql-bin.log
chown -R mysql:mysql /var/log/mysql
replicate_db=""

if [ "$DB_NAME_TO_SYNC" ]; then replicate_db="replicate-do-db=$DB_NAME_TO_SYNC"; fi

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

# Replication Settings - Slave
server-id=2
log_bin=/var/log/mysql/mysql-bin.log
$replicate_db
log_slave_updates=1
read_only=1
EOF

service mysqld restart
service mysqld status

echo "....................................................................."
echo "Done"
