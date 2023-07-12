#!/bin/bash

MYSQL_NEW_ROOT_PASS=Neo@1234
MYSQL_NEW_USER=neomysql
MYSQL_NEW_USER_PASS=Neo@1234

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

echo "Done"
