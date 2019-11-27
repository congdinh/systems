# General

- Os: Centos 7.x
- Mongodb: 4.2.x (latest) MongoDB has released a new stable version 4.2 with lots of major enhancements. This tutorial latest tested on CentOS 7 and help you to install MongoDB 4.2 on CentOS 8/7/6 and RHEL 8/7/6 systems.

## MongoDB

> MongoDB, the database for modern applications. If you are not familiar with MongoDB, its a general purpose, document based, distributed database.

> We will setup a 3 Node Replica Set MongoDB Cluster and go through a couple of scenarios to showcase data durability on how MongoDB can recover from node failures using replication.

> MongoDB Replica Sets are Groups of mongod proceeses that maintain the same dataset. Replica Sets provide high availability and redundancy. Replication provides redundancy and increases data availability. Copies of the data are replicated across nodes (mongod processes), replication provides a level of fault tolerance against the loss of a single database server.

> Replication can provide increased read capacity, as applications can be configured to read from the slave nodes and write to the primary nodes. With data locality, you can spread your nodes accross regions and let the applications read from the nodes closest to them.

> In a replica set, a primary receives all the write operations and you can only have one primary capable of confirming writes. The primary records all the changes in its oplog.

> Replica sets also fail over automatically, so if one of the members becomes unavailable, a new primary host is elected and your data is still accessible. That means, when a primary replica fails, the replica set automatically conducts an election process to determine which secondary should become the primary.

# Installing
#### Steps to remember
- First you need to create three ec2 instances.
- Set the hostname of each instance.
- Configure the host files in path /etc/hosts.
- To create a replica set, you’ll need at least three instances with MongoDB installed.
- Initialize the master(primary) database server and add the secondary servers as slaves.

#### Update Host Files
Update IP and name server in /etc/hosts file

#### Install Mongo 4.2.x single each server

https://docs.mongodb.com/manual/tutorial/install-mongodb-on-red-hat/

Using .rpm Packages (Recommended)
Configure the package management system (yum).
Create a /etc/yum.repos.d/mongodb.repo file so that you can install MongoDB directly using yum.
Add MongoDB Yum Repository:
```
vi /etc/yum.repos.d/mongodb.repo
```
```
[MongoDB]
name=MongoDB Repository
baseurl=http://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
```

Install the MongoDB packages.
```
sudo yum install -y mongodb-org
```

Starting MongoDB.
```
sudo systemctl start mongod
sudo systemctl enable mongod
```

Restart MongoDB.
```
sudo service mongod restart
```

Verifying MongoDB Installation and Check MongoDB Version
```
mongod --version
mongo
```

Testing MongoDB
```
> use mydb;
> db.test.save( { a: 1 } )
> db.test.find()
{ "_id" : ObjectId("54fc2a4c71b56443ced99ba2"), "a" : 1 }
```

# Config Mongod Replicate
Edit mongo config file on each server

At server-node-1

Edit file /etc/mongod.conf with full content below:
```
# mongo-cluster-1
storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo

operationProfiling:
  mode: "slowOp"
  slowOpThresholdMs: 50

replication:
  replSetName: data-replset
```

At server-node-2

Edit file /etc/mongod.conf with full content below:
```
# mongo-cluster-2
storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo

operationProfiling:
  mode: "slowOp"
  slowOpThresholdMs: 50

replication:
  replSetName: data-replset
```

At server-node-3

Edit file /etc/mongod.conf with full content below:
```
# mongo-cluster-3
storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo

operationProfiling:
  mode: "slowOp"
  slowOpThresholdMs: 50

replication:
  replSetName: data-replset
```

### Restart MongoDB
```
sudo service mongod restart
```

Verifying MongoDB Update config
```
mongo
```

# Initialize the MongoDB Replica Set

When mongodb starts for the first time it allows an exception that you can logon without authentication to create the root account, but only on localhost. The exception is only valid until you create the user.

### On server-node-1: Set Primary Node

```
mongo --host 127.0.0.1 --port 27017
MongoDB shell version v4.2.1
connecting to: mongodb://127.0.0.1:27017/?gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("14ac25ae-016a-4456-b451-60b5d7e866c7") }
MongoDB server version: 4.2.1
Welcome to the MongoDB shell.
>
```
Switch to the admin database and initialize the mongodb replicaset:
```
> use admin
switched to db admin
> rs.initiate( {
  _id : "data-replset",
  members: [
      { _id: 0, host: "ip-server-node-1:27017" },
      { _id: 1, host: "ip-server-node-2:27017" },
      { _id: 2, host: "ip-server-node-3:27017" }
  ]
})
```
Check replicaset and update Master node (Primary).
```
> rs.status()
> rs.isMaster()
> rs.isMaster()['ismaster']
> rs.isMaster()['me']
```
### On server-node-2 and server-node-3: Set Secondary Node
When we have a replica set we can write to our Primary (master) node and Read from our Secondary (slave) nodes. Before we can read from the secondary nodes, we need to tell mongodb that we want to read.

By default when you connect to a secondary node and want to read you will get this exception.
Check replicaset and access to database:
```
> rs.status()
> show databases;
  E QUERY    [js] Error: listDatabases failed:{
  "operationTime" : Timestamp(1562101152, 1),
  "ok" : 0,
  "errmsg" : "not master and slaveOk=false",
  "code" : 13435,
  "codeName" : "NotMasterNoSlaveOk”,
  ...
```
We first need to instruct mongodb that we want to read:

```
> rs.slaveOk()
```
Now that we have done that, we can read from the secondary:
```
> show databases;
  admin   0.000GB
  config  0.000GB
  local   0.000GB
```
# Testing Database Replication
> Test case

Create database on Primary Node (server-node-1):
```
mongo
> show database;
> use exampleDB
> for (var i = 0; i <= 10; i++) db.exampleCollection.insert( { x : i } )
> db.exampleCollection.find();
```
Review on Secondary Node (server-node-2 and server-node-3):
```
mongo
> show database;
> use exampleDB
> db.exampleCollection.find();
```

> Completed
