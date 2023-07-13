## Set up Master-Slave replication in MySQL Server

> Install Mysql in Master server (if not already installed)

```sh
sh ./script/install_mysql.sh
```

> Follow these steps:

### 1. MySQL Slave server

- Update some variables in script/slave.sh file.

```sh
MYSQL_NEW_ROOT_PASS=Neo@1234
MYSQL_NEW_USER=neomysql
MYSQL_NEW_USER_PASS=Neo@1234
# Empty this variable to sync all databases
DB_NAME_TO_SYNC=
```

- Run file slave.sh to create new slave configuration.
- Install Mysql DB v5.7

```sh
sh ./script/slave.sh
```

### 2. MySQL Master server

- Update some variables in script/master.sh file.

```sh
MYSQL_ROOT_PASS=Neo@1234
MYSQL_SLAVE_PASS=Neo@1234

SLAVE_IP=
SLAVE_SSH_USER=
SLAVE_SSH_PASS=
```

- Run file master.sh to update new master configuration and create new slave user.
- Lock, backup database and restore in new slave server.

```sh
sh ./script/master.sh
```

- Lock database with current user:

```sh
# LOCK DATABASE
mysql -u root -p
mysql> FLUSH TABLES WITH READ LOCK;
```

### 3. Run file slave_run_after.sh to restore database.

- Update some variables in script/slave_run_after.sh file.
  > Copy Master Position number from Master DB result log;
  > mysql> SHOW MASTER STATUS;
```
+------------------+----------+--------------+------------------+-------------------+
| File | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000005 | 154 | | | |
+------------------+----------+--------------+------------------+-------------------+
```

```sh
MYSQL_NEW_USER=neomysql
MYSQL_NEW_USER_PASS=Neo@1234

MASTER_HOST=
# this value from Master Position.
MASTER_LOG_POS=154
MASTER_LOG_FILE=mysql-bin.000005
MYSQL_SLAVE_PASS=Neo@1234
```

- Run file slave_run_after.sh

```sh
sh ./script/slave_run_after.sh
```

### 4. In Master DB

- Unlock database

```sh
mysqldump -u root -p
mysql> UNLOCK TABLES;
```

### 5. Testing

- Master DB

```sh
mysql -u root -p -e "\
SHOW DATABASES; \
SHOW MASTER STATUS; \
"
```

- Test with data

```sh
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
```

- Slave DB

```sh
mysql -u root -p -e "\
SHOW DATABASES; \
SHOW MASTER STATUS; \
SHOW SLAVE STATUS\G; \
"
```
