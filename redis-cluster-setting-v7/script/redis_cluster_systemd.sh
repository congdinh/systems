CUR_DIR="/etc/redis"
cd $CUR_DIR
ports=$@

for port in $ports; do
  # Create redis systemd service
  cat >/etc/systemd/system/redis_${port}.service <<EOF
[Unit]
Description=Redis data structure server
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=$(which redis-server) ${CUR_DIR}/redis-cluster/${port}/redis_${port}.conf
Type=notify
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  # Create Redis sentinel systemd service
  cat >/etc/systemd/system/redis_sentinel_2${port}.service <<EOF
[Unit]
Description=Redis Sentinel
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=$(which redis-server) ${CUR_DIR}/redis-cluster/${port}/redis_sentinel_2${port}.conf --sentinel --supervised systemd
Type=notify
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
done
