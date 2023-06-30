#!/bin/bash
echo "Begin Redis Cluster................................"
CUR_DIR="/opt/redis-cluster-setting-v7"
ports=$@;

echo "Downloading Redis..."
yum install gcc wget systemd-devel -y
cd /opt

wget https://github.com/redis/redis/archive/7.0.11.tar.gz
tar -xvzf 7.0.11.tar.gz
cd redis-7.0.11
make
cd src & make install
echo "Installed Redis CLI"
echo "--------------------------------"

cd $CUR_DIR
echo "Running Redis cluster script..."
source redis_cluster_config.sh $ports
echo "Done Redis cluster script"

ls -la /etc/redis/redis-cluster
sleep 2

echo "--------------------------------"
echo "Running Redis systemd script..."
source redis_cluster_systemd.sh $ports
echo "Done Redis systemd script"

sleep 2
echo "--------------------------------"

echo "Starting Redis Cluster..."
for port in $ports; do
systemctl start redis_${port}
systemctl enable redis_${port}
systemctl status redis_${port}
done

sleep 2
echo "--------------------------------"

echo "Verify Redis PING PONG..."
for port in $ports; do
redis-cli -p ${port} ping;
done
netstat -antlp | grep -i listen| grep redis

sleep 2
echo "--------------------------------"

echo "Starting Redis Sentinel..."
for port in $ports; do
systemctl start sentinel_${port}
systemctl enable sentinel_${port}
systemctl status sentinel_${port}
done

echo "Setup Redis Cluster Finished!"