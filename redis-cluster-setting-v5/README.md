# Install Guide redis-cluster with sentinel auto failover.

[Cluster Tutorial](https://redis.io/topics/cluster-tutorial)

[Package Redis Latest](https://redis.io/download)

Install with each RedisDB server machine and run all at root permission.

## Install Redis library

Download and compile the latest stable Redis version using the special URL that always points to the latest stable Redis Install Redis:

```
$ cd redis-cluster-setting-server
$ tar xzf redis-5.0.4.tar.gz
$ cd redis-5.0.4
$ make
$ make install
```

The binaries that are now compiled are available in the src directory. Run Redis with:

```
$ cd src & make install
```

## Create folder service

Configure Redis Server in Linux:

Next, you need to configure redis for a development environment to be managed by the init system (systemd for the purpose of this tutorial). Start by creating the necessary directories for storing redis config files and your data:

```
$  mkdir -p /etc/redis /var/run/redis /var/log/redis /var/redis/7000 /var/redis/7001 /var/redis/7002
```

## Copy and config service

At folder: redis-cluster-setting-server
Then open the configuration file and update a few settings as follows.

- Update redis-sentinel IP at config folder:
  > Edit file: sentinel_7000.conf, sentinel_7001.conf, sentinel_7002.conf

> Replace 127.0.0.1 -> IP server running (example: 192.168.1.110)

### Now copy the template redis configuration file provided, into the directory you created above.

- Copy redis-cluster config:

```
$  cp ./config/7000.conf /etc/redis/
$  cp ./config/7001.conf /etc/redis/
$  cp ./config/7002.conf /etc/redis/
```

- Copy redis-sentinel config:

```
$  cp ./config/sentinel_7000.conf /etc/redis/
$  cp ./config/sentinel_7001.conf /etc/redis/
$  cp ./config/sentinel_7002.conf /etc/redis/
```

## Create Redis Systemd Unit File

Now you need to create a systemd unit file for redis in order to control the daemon, by running the following command.

### Copy script redis-cluster:

```
$  cp ./script/redis_7000 /etc/init.d/
$  chmod 750 /etc/init.d/redis_7000
$  chkconfig redis_7000 on
```

### Copy script redis-sentinel:

```
$  cp ./script/sentinel_7000 /etc/init.d/
$  chmod 750 /etc/init.d/sentinel_7000
$  chkconfig sentinel_7000 on
```

### Clone file redis_7000 to redis_7001, redis_7002 by link file:

```
$  ln -s /etc/init.d/redis_7000 /etc/init.d/redis_7001
$  chmod 750 /etc/init.d/redis_7001
$  chkconfig redis_7001 on
```

```
$  ln -s /etc/init.d/redis_7000 /etc/init.d/redis_7002
$  chmod 750 /etc/init.d/redis_7002
$  chkconfig redis_7002 on
```

### Clone file sentinel_7000 to sentinel_7001, sentinel_7002 by link file:

```
$  ln -s /etc/init.d/sentinel_7000 /etc/init.d/sentinel_7001
$  chmod 750 /etc/init.d/sentinel_7001
$  chkconfig sentinel_7001 on
```

```
$  ln -s /etc/init.d/sentinel_7000 /etc/init.d/sentinel_7002
$  chmod 750 /etc/init.d/sentinel_7002
$  chkconfig sentinel_7002 on
```

## Manage and Test Redis Server in Linux

Once you have performed all the necessary configurations, you can now start the Redis server for now, enable it to auto-start at system boot; then view its status as follows.

- Redis server:

```
$  systemctl start redis_7000 redis_7001 redis_7002
$  systemctl enable redis_7000 redis_7001 redis_7002
$  systemctl status redis_7000 redis_7001 redis_7002
```

- Verify that Redis has installed successfully with by running the command:

```
$  /usr/local/bin/redis-cli -p 7000 ping
$  /usr/local/bin/redis-cli -p 7001 ping
$  /usr/local/bin/redis-cli -p 7002 ping
```

- Port listening status

```
$ netstat -antlp | grep -i listen| grep redis
```

## Create cluster replicas

> We have 3 example IP servers: 192.168.1.110, 192.168.1.111, 192.168.1.112
> And each server have 3 ports: 7000, 7001, 7002.

Use your IP:Port to change example with command below:

```
$  /usr/local/bin/redis-cli --cluster create \
192.168.1.110:7000 192.168.1.110:7001 192.168.1.110:7002 \
192.168.1.111:7000 192.168.1.111:7001 192.168.1.111:7002 \
192.168.1.112:7000 192.168.1.112:7001 192.168.1.112:7002 \
--cluster-replicas 1
```

Result status clustering example:

```
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 192.168.1.110:7004 to 192.168.1.110:7000
Adding replica 192.168.1.110:7005 to 192.168.1.110:7001
Adding replica 192.168.1.110:7003 to 192.168.1.110:7002
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: e2985e8dbdb3d8063e2d69d00bf0d992dff5d06e 192.168.1.110:7000
   slots:[0-5460] (5461 slots) master
M: f6375cd48e1e922370fe4931097039be82ee06b8 192.168.1.110:7001
   slots:[5461-10922] (5462 slots) master
M: ba0b73d96373961825afa754c26f827a1ca81bc2 192.168.1.110:7002
   slots:[10923-16383] (5461 slots) master
S: 94ad7f9da8ec6986a80fee31a4d0fc58d34bb1f9 192.168.1.110:7003
   replicates f6375cd48e1e922370fe4931097039be82ee06b8
S: 63b7512ccd362863cb3b1136f99f38ed9f53ec4d 192.168.1.110:7004
   replicates ba0b73d96373961825afa754c26f827a1ca81bc2
S: 3cf12546d7475d577a47bfcde4e6f6230689e3d0 192.168.1.110:7005
   replicates e2985e8dbdb3d8063e2d69d00bf0d992dff5d06e
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
....
>>> Performing Cluster Check (using node 192.168.1.110:7000)
M: e2985e8dbdb3d8063e2d69d00bf0d992dff5d06e 192.168.1.110:7000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 94ad7f9da8ec6986a80fee31a4d0fc58d34bb1f9 192.168.1.110:7003
   slots: (0 slots) slave
   replicates f6375cd48e1e922370fe4931097039be82ee06b8
S: 3cf12546d7475d577a47bfcde4e6f6230689e3d0 192.168.1.110:7005
   slots: (0 slots) slave
   replicates e2985e8dbdb3d8063e2d69d00bf0d992dff5d06e
M: ba0b73d96373961825afa754c26f827a1ca81bc2 192.168.1.110:7002
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: f6375cd48e1e922370fe4931097039be82ee06b8 192.168.1.110:7001
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
S: 63b7512ccd362863cb3b1136f99f38ed9f53ec4d 192.168.1.110:7004
   slots: (0 slots) slave
   replicates ba0b73d96373961825afa754c26f827a1ca81bc2
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered
```

- Check redis cluster nodes:

```
$  /usr/local/bin/redis-cli -p 7000 cluster nodes
```

## Manage and Test Redis Sentinel

- Redis sentinel:

```
$  systemctl start sentinel_7000 sentinel_7001 sentinel_7002
$  systemctl enable sentinel_7000 sentinel_7001 sentinel_7002
$  systemctl status sentinel_7000 sentinel_7001 sentinel_7002
```

## Connect to any redis sentinel

```
$ /usr/local/bin/redis-cli -p 27000
```

### To see current masters

```
$ 192.168.1.110:27000> SENTINEL masters
```

### To see slaves for given cluster

```
$ 192.168.1.110:27000> SENTINEL slaves redis-cluster
```

## Connect to redis master and execute below command

```
/usr/local/bin/redis-cli -h 192.168.1.110 -p 7000
192.168.1.110:7000> DEBUG SEGFAULT
192.168.1.110:7000> SENTINEL masters
```
