adduser redis
mkdir -p /etc/redis /var/log/redis /var/run/redis

CUR_DIR="/etc/redis"
cd $CUR_DIR
mkdir -p ${CUR_DIR}/redis-cluster
cd ${CUR_DIR}/redis-cluster
ip_addr=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')

for port in 7000 7001 7002 7003 7004 7005; do
  mkdir -p ${CUR_DIR}/redis-cluster/${port}
# Create redis config file
  cat > ${CUR_DIR}/redis-cluster/${port}/redis_${port}.conf <<EOF
### Redis Config v7 Turning
bind 0.0.0.0
port $port
pidfile "/var/run/redis/redis_${port}.pid"
dir "${CUR_DIR}/redis-cluster/${port}"

# Logging
logfile "/var/log/redis/redis_${port}.log"
loglevel notice

# Cluster configuration
cluster-enabled yes
cluster-config-file "${CUR_DIR}/redis-cluster/${port}/nodes.conf"
cluster-node-timeout 5000

# General performance optimizations
daemonize yes
supervised systemd
tcp-keepalive 300
timeout 0
repl-timeout 60
protected-mode no

# The client output buffer limits
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 0 0 0

# Handle dangerous commands
rename-command FLUSHDB ""
rename-command FLUSHALL ""

# Persistence (if required)
save 900 1
save 300 10
save 60 100000
stop-writes-on-bgsave-error yes

# Replication (if required)
replica-serve-stale-data yes
repl-diskless-sync no
repl-diskless-sync-delay 5

# Disable AOF persistence (if not needed)
appendonly no

### Redis Config v7.0.11 Default
databases 16
always-show-logo no
set-proc-title yes
proc-title-template "{title} {listen-addr} {server-mode}"
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
rdb-del-sync-files no
replica-read-only yes
repl-diskless-sync-max-replicas 0
repl-diskless-load disabled
repl-disable-tcp-nodelay no
replica-priority 100
acllog-max-len 128
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
lazyfree-lazy-user-del no
lazyfree-lazy-user-flush no
oom-score-adj no
oom-score-adj-values 0 200 800
disable-thp yes
appendfilename "appendonly.aof"
appenddirname "appendonlydir"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
aof-timestamp-enabled no

slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-listpack-entries 512
hash-max-listpack-value 64
list-max-listpack-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-listpack-entries 128
zset-max-listpack-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
hz 10
dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes
jemalloc-bg-thread yes
EOF

# Create sentinel config file
cat > ${CUR_DIR}/redis-cluster/${port}/redis_sentinel_2${port}.conf <<EOF
bind 0.0.0.0
port 2${port}
sentinel monitor redis-cluster ${ip_addr} ${port} 1
sentinel down-after-milliseconds redis-cluster 5000
sentinel parallel-syncs redis-cluster 1
sentinel failover-timeout redis-cluster 10000
sentinel deny-scripts-reconfig yes
daemonize yes
pidfile "/var/run/redis/redis_sentinel_2${port}.pid"
dir "${CUR_DIR}/redis-cluster/${port}/"
EOF
chown -R redis.redis $CUR_DIR/redis-cluster /var/log/redis /var/run/redis
done