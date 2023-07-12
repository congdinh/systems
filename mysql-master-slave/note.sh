https://tecadmin.net/install-mysql-5-7-centos-rhel/

Default password to testing: Neo@1234

# REMOVE mysqld
service mysqld stop
yum remove -y mysql mysql-community-server mysql57-community-release-el7-11
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/my.cnf.rpmsave
sudo rm -rf /var/log/mysql*

# INSTALL mysqld
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 
sudo yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm 
sudo yum install mysql-community-server 
sudo systemctl start mysqld 
sudo systemctl status mysqld 

grep 'A temporary password' /var/log/mysqld.log |tail -1 
> 2023-07-06T02:58:51.246779Z 1 [Note] A temporary password is generated for root@localhost:
kDwiA=klt4da

/usr/bin/mysql_secure_installation 
> New password: Neo@1234
> Press y for all answers

# mysql -u root -pNeo@1234 -e "SET PASSWORD FOR root@localhost = PASSWORD('Neo@1234');FLUSH PRIVILEGES;" 

#Create new user
mysql -u root -p -e "\
CREATE USER 'neomysql'@'%' IDENTIFIED BY 'Neo@1234'; \
GRANT ALL PRIVILEGES ON *.* TO 'neomysql'@'%'; \
SHOW GRANTS FOR neomysql; \
FLUSH PRIVILEGES;
"

mysql -u neomysql -p -e "\
CREATE DATABASE dbtest; \
SHOW DATABASES; \
SHOW MASTER STATUS; \
"
----------------------------------------------------------------
#### MASTER DB;
mkdir /var/log/mysql
touch /var/log/mysql/mysql-bin.log
chown -R mysql:mysql /var/log/mysql

vim /etc/my.cnf

service mysqld restart

mysql -u neomysql -p -e "\
SHOW DATABASES; \
SHOW MASTER STATUS; \
"

# Replace SLAVE_IP
mysql -u root -p -e "\
CREATE USER 'slave'@'SLAVE_IP' IDENTIFIED BY 'Neo@1234'; \
GRANT REPLICATION SLAVE ON *.* TO 'slave'@'SLAVE_IP'; \
FLUSH PRIVILEGES; \
"

Next, turn on the lock on your databases to prevent the change in data.

mysql -u neomysql -p -e "\
FLUSH TABLES WITH READ LOCK; \
"

mysqldump -u neomysql -p --all-databases --master-data | gzip -9 > /opt/master-data.sql.gz

scp master-data.sql.gz root@SLAVE_IP:~

----------------------------------------------------------------
#### SLAVE DB;
mkdir /var/log/mysql
touch /var/log/mysql/mysql-bin.log
chown -R mysql:mysql /var/log/mysql

vim /etc/my.cnf

service mysqld restart 
service mysqld status

# Need a file dump
gunzip < master-data.sql.gz | mysql -u neomysql -p

# Replace MASTER_IP, MASTER_LOG_FILE, MASTER_LOG_POS
mysql -u neomysql -p -e "\
SHOW MASTER STATUS; \
SHOW DATABASES; \
STOP SLAVE; \
CHANGE MASTER TO MASTER_HOST='MASTER_IP', MASTER_USER='slave', MASTER_PASSWORD='Neo@1234', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=154; \
START SLAVE; \
SHOW SLAVE STATUS\G; \
"

----------------------------------------------------------------
#### BACK TO MASTER;
mysqldump -u root -p
mysql> UNLOCK TABLES;

# Test DB Sync
mysql -u neomysql -p -e "\
USE dbtest; \
INSERT INTO user (username, email, password)\
VALUES ('michael_brown', 'michael.brown@example.com', 'password123'),\
       ('sarah_jackson', 'sarah.jackson@example.com', 'password456'),\
       ('adam_wilson', 'adam.wilson@example.com', 'password789');\
SELECT * FROM user; \
"

----------------------------------------------------------------
# NOTES:
#Backup database:
mysqldump --opt -u [uname] -p [dbname] > [backupfile.sql]

#Backup & Gzip database:
mysqldump -u [uname] -p [dbname] | gzip -9 > [backupfile.sql.gz]

#Restore MySQL Dump:
mysql -u [user] -p [database_name] < [filename].sql

#Restore Gzip Dump:
gunzip < [backupfile.sql.gz] | mysql -u [uname] -p [dbname]

mysqldump -u root -p --all-databases --master-data | gzip -9 > master-data.sql.gz
mysqldump -u root -p dbtest --master-data | gzip -9 > master-data.sql.gz

# Test data
mysql -u neomysql -p -e "\
CREATE DATABASE dbtest; \
USE dbtest; \
CREATE TABLE user ( \
    id INT AUTO_INCREMENT PRIMARY KEY, \
    username VARCHAR(50) NOT NULL, \
    email VARCHAR(100) NOT NULL, \
    password VARCHAR(100) NOT NULL, \
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP \
); \
INSERT INTO user (username, email, password) \
VALUES ('john_doe', 'john.doe@example.com', 'password123'), \
       ('jane_smith', 'jane.smith@example.com', 'password456'), \
       ('mark_johnson', 'mark.johnson@example.com', 'password789'); \
SELECT * FROM user; \
"

mysql -u neomysql -p -e "\
USE dbtest; \
INSERT INTO user (username, email, password) \
VALUES ('alice_walker', 'alice.walker@example.com', 'password123'), \
       ('bob_smith', 'bob.smith@example.com', 'password456'), \
       ('emma_jones', 'emma.jones@example.com', 'password789'); \
SELECT * FROM user; \
"

show databases;
use dbtest;
select * from user;
delete from user where username="john_doe";

INSERT INTO user (username, email, password)
VALUES ('alice_walker', 'alice.walker@example.com', 'password123'),
       ('bob_smith', 'bob.smith@example.com', 'password456'),
       ('emma_jones', 'emma.jones@example.com', 'password789');
