# Install Guide redis-cluster with sentinel auto failover.

[Cluster Tutorial](https://redis.io/topics/cluster-tutorial)

[Package Redis Latest](https://redis.io/download)

Common cluster model:
- 6 node cluster - install on 2 or 3 servers (for production), 3 nodes per server.
- 6 node cluster - install on 1 server (for lab/test env)

In this article, will install all 6 redis on 1 server. Includes 3 masters (33% data * 3) and 3 slaves for master backup.
```
7000(M)-7003(S)
7001(M)-7004(S)
7002(M)-7005(S)
```

Install with each RedisDB server machine and run all at root permission.

## Install Redis library

Download and compile the latest stable Redis version using the special URL that always points to the latest stable Redis Install Redis:

```
$ yum install gcc wget systemd-devel -y
$ cd /opt
$ wget https://github.com/redis/redis/archive/7.0.11.tar.gz
$ tar -xvzf 7.0.11.tar.gz
$ cd redis-7.0.11
$ make
```

The binaries that are now compiled are available in the src directory. Run Redis with:

```
$ cd src & make install
```

## Prepare config for Cluster

Configure Redis Server in Linux.

Next, you need to configure redis for a development environment to be managed by the init system (systemd for the purpose of this tutorial). Start by running bash script to create redis config files:

> Note: Available to update the number of ports (nodes) per server in script file bellow: 7000 7001 7002 7003 7004 7005

Download folder config: redis-cluster-setting-v7
```
$ wget ...
$ mv ./redis-cluster-setting-v7 /opt
```

- Prepare new Redis Config File:
```
$ bash /opt/redis-cluster-setting-v7/script/redis_cluster_config.sh

# Check these files
$ ls -la /etc/redis/redis-cluster
```

- Prepare new Redis Systemd Service File: 
```
$ bash /opt/redis-cluster-setting-v7/script/redis_cluster_systemd.sh

# Check these files
$ ls -la /etc/systemd/system/redis_*
```

## Running Redis Systemd

Once you have performed all the necessary configurations, you can now start the Redis server for now, enable it to auto-start at system boot; then view its status as follows.

Now you need to run a systemd service for redis in order to control the daemon, by running the following command.


- Redis server:

```
$  systemctl start redis_7000 redis_7001 redis_7002 redis_7003 redis_7004 redis_7005
$  systemctl enable redis_7000 redis_7001 redis_7002 redis_7003 redis_7004 redis_7005
$  systemctl status redis_7000 redis_7001 redis_7002 redis_7003 redis_7004 redis_7005
```

- Verify that Redis has installed successfully with by running the command:

```
$  /usr/local/bin/redis-cli -p 7000 ping
$  /usr/local/bin/redis-cli -p 7001 ping
$  /usr/local/bin/redis-cli -p 7002 ping
$  /usr/local/bin/redis-cli -p 7003 ping
$  /usr/local/bin/redis-cli -p 7004 ping
$  /usr/local/bin/redis-cli -p 7005 ping
```

- Port listening status

```
$ netstat -antlp | grep -i listen| grep redis
```

## Create Cluster Replicas

> We have 1 example IP server: 192.168.1.110

> Each server have 6 ports: 7000, 7001, 7002, 7003, 7004, 7005

> Setting up the cluster with 1 replicas

Use your IP:Port to change example with command below:

```
$  /usr/local/bin/redis-cli --cluster create \
192.168.1.110:7000 192.168.1.110:7001 192.168.1.110:7002 192.168.1.110:7003 192.168.1.110:7004 192.168.1.110:7005
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
$  systemctl start sentinel_7000 sentinel_7001 sentinel_7002 sentinel_7003 sentinel_7004 sentinel_7005
$  systemctl enable sentinel_7000 sentinel_7001 sentinel_7002 sentinel_7003 sentinel_7004 sentinel_7005
$  systemctl status sentinel_7000 sentinel_7001 sentinel_7002 sentinel_7003 sentinel_7004 sentinel_7005
```

### Connect to any redis sentinel

- Connect to redis sentinel
```
$ /usr/local/bin/redis-cli -p 27000
```

- To see current masters
```
$ 192.168.1.110:27000> SENTINEL masters
```

- To see slaves for given cluster
```
$ 192.168.1.110:27000> SENTINEL slaves redis-cluster
```

## Connect to redis master and execute below command
- Testing redis cluster:
```
/usr/local/bin/redis-cli -h 192.168.1.110 -p 7000 -c
192.168.1.110:7000> CLUSTER NODES
192.168.1.110:7000> DEBUG SEGFAULT
192.168.1.110:7000> SENTINEL masters
192.168.1.110:7000> info replication
192.168.1.110:7000> INFO

```

- Run a few SET and GET commands to check the behavior of Redis:
```
192.168.1.35:7000> set a 1
-> Redirected to slot [15495] located at 192.168.1.110:7000
OK
192.168.1.110:7000> set b 2
-> Redirected to slot [3300] located at 192.168.1.35:7000
OK
192.168.1.35:7000> set c 3
-> Redirected to slot [7365] located at 192.168.1.176:7000
OK
192.168.1.176:7000> set d 4
-> Redirected to slot [11298] located at 192.168.1.110:7000
OK
192.168.1.110:7000> get b
-> Redirected to slot [3300] located at 192.168.1.35:7000
"2"
192.168.1.35:7000> get a
-> Redirected to slot [15495] located at 192.168.1.110:7000
"1"
192.168.1.110:7000> get c
-> Redirected to slot [7365] located at 192.168.1.176:7000
"3"
192.168.1.176:7000> get d
-> Redirected to slot [11298] located at 192.168.1.110:7000
"4"
192.168.1.110:7000>
```

- Testing failover cluster:
```
$ service redis_7001 stop

$ redis-cli -p 7000 cluster nodes
127.0.0.1:7000> CLUSTER NODES
01b50960455d43225766190c5c6144e73128f314 192.168.1.110:7001@17001 master,fail - 1688119350608 1688119348095 2 disconnected
d360cd23d8e3e39b5354c2d89373037b4be9f3bd 192.168.1.110:7003@17003 slave 64b10129a50b4330e578e54d37486d91a6a84ea5 0 1688119363185 1 connected
12f8e1b2c6980d0293459d1ba7e40a5c24bb6a75 192.168.1.110:7005@17005 slave 453ee9044d1c4c8fa4ef36477312b20c4116b10a 0 1688119362000 3 connected
64b10129a50b4330e578e54d37486d91a6a84ea5 192.168.1.110:7000@17000 myself,master - 0 1688119361000 1 connected 0-5460
9ee49d0ac04a244978e17ab79be2123572475d67 192.168.1.110:7004@17004 master - 0 1688119362178 7 connected 5461-10922
453ee9044d1c4c8fa4ef36477312b20c4116b10a 192.168.1.110:7002@17002 master - 0 1688119362581 3 connected 10923-16383
```

## Benchmark Redis Cluster

- Using redis-benchmark:
```
1.Stress master 0:
$ redis-benchmark -q -h localhost -p 7000 -P 16 -n 1000000 set b “12345”

2. Stress master 1:
$ redis-benchmark -q -h localhost -p 7001 -P 16 -n 1000000 set c “56789”

3. Stress master 2:
$ redis-benchmark -q -h localhost -p 7002 -P 16 -n 1000000 set a “34567”

4. Benchmark with multi cluster
$ redis-benchmark -n 10000000 -t set,get -P 16 -q -h localhost -p 7000 --cluster
```

> Results: 
```
Cluster has 3 master nodes:

Master 0: 64b10129a50b4330e578e54d37486d91a6a84ea5 192.168.1.110:7000
Master 1: 9ee49d0ac04a244978e17ab79be2123572475d67 192.168.1.110:7004
Master 2: 453ee9044d1c4c8fa4ef36477312b20c4116b10a 192.168.1.110:7002

SET: 886603.38 requests per second, p50=0.551 msec
GET: 1419849.50 requests per second, p50=0.335 msec
```

- Using redislabs/memtier_benchmark (https://codedamn.com/news/backend/benchmarking-redis-performance):
```
docker run --rm redislabs/memtier_benchmark:latest --help

docker run --rm redislabs/memtier_benchmark:latest -h 127.0.0.1 -p 7000 --cluster-mode -t 8 -c 100 -R --ratio=1:2 -d 500 -n 20000

docker run --rm redislabs/memtier_benchmark:latest -h 127.0.0.1 -p 7000 --cluster-mode --hide-histogram --test-time=60
```