# Install ES Cluster 8 - Cerebro - Kibana

https://www.golinuxcloud.com/setup-configure-elasticsearch-cluster-7-linux/

https://computingforgeeks.com/install-elastic-stack-elk-on-rhel-centos/

https://www.elastic.co/guide/en/elasticsearch/reference/current/configuring-stack-security.html#configuring-stack-security

https://www.elastic.co/guide/en/elasticsearch/reference/8.8/rpm.html

https://www.elastic.co/guide/en/kibana/current/rpm.html

When you start Elasticsearch for the first time, the node startup process tries to automatically configure security for you. This guideline is following the auto configured security from ES.

Setup in 3 server nodes:

Create user:
useradd name_user
passwd name_user

Pass: ...

# ADD PERMISSION

visudo
name_user ALL=(ALL) ALL

Setting I/O
================

```
vim /etc/sysctl.conf
fs.file-max = 100000

swapoff -a
```

```
vim /etc/security/limits.conf

*          soft nproc          100000
*          hard nproc          100000
*          soft nofile         100000
*          hard nofile         100000
elasticsearch  -  nofile  65536

elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
```

```
vim /etc/security/limits.d/90-nproc.conf

vim /etc/security/limits.d/20-nproc.conf
*          soft    nproc     100000
root       soft    nproc     unlimited
```

```
ulimit -n 655356
ulimit -u 655356

ulimit -a
```

# SET HOSTS

```
vim /etc/hosts

127.0.0.1 new-neo-hot-1 cerebro-es-host
127.0.0.2 new-neo-hot-2 cerebro-es-host
127.0.0.3 new-neo-hot-3 cerebro-es-host
```

# JAVA

yum install java-1.8.0-openjdk
https://tecadmin.net/install-java-8-on-centos-rhel-and-fedora/

Or java-11:

```
sudo yum -y install java-11-openjdk java-11-openjdk-devel

# java -version
# which java

# sudo tee /etc/profile.d/java11.sh <<EOF
export JAVA_HOME=\$(dirname \$(dirname \$(readlink \$(readlink \$(which javac)))))
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar
EOF

# source /etc/profile.d/java11.sh


sudo alternatives --list
```

# Install ES for all nodes

```
cd /opt

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.8.0-x86_64.rpm
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.8.0-x86_64.rpm.sha512
shasum -a 512 -c elasticsearch-8.8.0-x86_64.rpm.sha512
sudo rpm --install elasticsearch-8.8.0-x86_64.rpm
```

If you set a custom data path for Elasticsearch, you need to disable SELinux or set it in permissive mode for the path to be accessible.

```
sudo setenforce 0
```

Create path.repo directory:

```
mkdir /usr/share/elasticsearch/backup
chown elasticsearch:elasticsearch /usr/share/elasticsearch/backup
```

Config jvm.options at /etc/elasticsearch/jvm.options
Heap space = 50% RAM

```
# Xms represents the initial size of total heap space
# Xmx represents the maximum size of total heap space

-Xms12g
-Xmx12g
```

Config Memory lock:
The systemd service file (/usr/lib/systemd/system/elasticsearch.service)

```
vim /usr/lib/systemd/system/elasticsearch.service

[Service]

#  Memory lock
LimitMEMLOCK=infinity
```

sudo systemctl daemon-reload

# In ES - NODE 01

Config at /etc/elasticsearch/elasticsearch.yml

```
Init Es config with TLS auto generated:

vi elasticsearch.yml
====================

# Cluster / Node Basics
cluster.name: new-neo-cluster

node.name: new-neo-hot-1
network.host: 0.0.0.0
http.port: 59701
path.logs: /var/log/elasticsearch
path.data: /var/lib/elasticsearch
bootstrap.memory_lock: true
cluster.initial_master_nodes: ["new-neo-hot-1"]
xpack.watcher.enabled: false
xpack.ml.enabled: false

## License
xpack.license.self_generated.type: basic
# Enable security features
xpack.security.enabled: true
xpack.security.enrollment.enabled: true

# Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12

# Enable encryption and mutual authentication between cluster nodes
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
```

Run service elasticsearch

```
systemctl start elasticsearch
systemctl enable elasticsearch
systemctl status elasticsearch
```

```
Generate pass and node-key to using in Node02, Node03

# Elastic Password
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic --url http://localhost:59701
> ...

# Node - key for Node 02
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
> ...

# Node - key for Node 03
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
> ...

# Node - key for Kibana
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
> ...
```

```
# Backup TLS default config:
cp elasticsearch.yml elasticsearch.yml.bak

# Generate PEM file from CA certificate:
openssl x509 -in /etc/elasticsearch/certs/http_ca.crt -out /etc/elasticsearch/certs/elastic.pem -outform PEM

# Generate Fingerprint ID:
The certificate fingerprint can be calculated using openssl x509 with the certificate file:

openssl x509 -fingerprint -sha256 -noout -in /etc/elaticsearch/certs/http_ca.crt
```

```
Update final ES Config with our configuration

vi elasticsearch.yml
===================
# Cluster / Node Basics
cluster.name: new-neo-cluster

# Node can have abritrary attributes we can use for routing
node.name: new-neo-hot-1

# Node type
node.roles: ["master", "data", "data_hot", "ingest", "remote_cluster_client"]
# The ingest node intercepts bulk and index requests, it applies transformations, and it then passes the documents back to the index or bulk APIs. Currently 1 node in cluster have ingest.

# Network
network.host: 0.0.0.0
http.port: 59701

transport.host: 0.0.0.0

# Path node
path.logs: /var/log/elasticsearch
path.data: /var/lib/elasticsearch
path.repo: ["/usr/share/elasticsearch/backup"]

# Content sizing of an HTTP request
http.max_content_length: 300mb
http.max_initial_line_length: 100kb

# Cluster routing
# Handle disk to relocate shards away from a node
#cluster.routing.allocation.enable - disable/enable shard allocation (all-default)
#cluster.routing.allocation.disk.threshold_enabled- disk allocation decider
#cluster.info.update.interval- disk usage check interval
cluster:
  routing:
    allocation:
      allow_rebalance: indices_all_active
      enable: all
      node_concurrent_recoveries: 2
      cluster_concurrent_rebalance: 2
      disk:
        threshold_enabled: true
        watermark:
          flood_stage: 0.97
          low: 0.85
          high: 0.9
    rebalance:
      enable: all
  info:
    update:
      interval: 1m

# Force all memory to be locked, forcing the JVM to never swap
bootstrap.memory_lock: true

## thread_pool Settings ##
thread_pool:
  search:
    queue_size: 1000
  write:
    queue_size: 10000

# Indices settings
indices.memory.index_buffer_size: 30%
indices.memory.min_index_buffer_size: 96mb

# Cache Sizes
indices.fielddata.cache.size: 30%
indices.queries.cache.size: 15%

# Unicast Discovery
discovery.seed_hosts:
  - new-neo-hot-1
  - new-neo-hot-2
  - new-neo-hot-3

# X-PACK Security settings
# Set Watcher (disabled)
xpack.watcher.enabled: false
# Set Machine learning (disabled)
xpack.ml.enabled: false

## License
xpack.license.self_generated.type: basic

# Enable security features
xpack.security.enabled: true
xpack.security.audit.enabled: true
xpack.security.enrollment.enabled: true

# Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12

# Enable encryption and mutual authentication between cluster nodes
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
```

# In ES - NODE 02

```
# Enter node key to join cluster node:
/usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token [Enter-node-key-02 generated]

# Config ES
vi elasticsearch.yml
====================


# Cluster / Node Basics
cluster.name: new-neo-cluster

# Node can have abritrary attributes we can use for routing
node.name: new-neo-hot-2

# Node type
node.roles: ["master", "data", "data_hot"]

# Network
network.host: 0.0.0.0
http.port: 59701

transport.host: 0.0.0.0

# Path node
path.logs: /var/log/elasticsearch
path.data: /var/lib/elasticsearch
path.repo: ["/usr/share/elasticsearch/backup"]

# Content sizing of an HTTP request
http.max_content_length: 300mb
http.max_initial_line_length: 100kb

# Cluster routing
# Handle disk to relocate shards away from a node
#cluster.routing.allocation.enable - disable/enable shard allocation (all-default)
#cluster.routing.allocation.disk.threshold_enabled- disk allocation decider
#cluster.info.update.interval- disk usage check interval
cluster:
  routing:
    allocation:
      allow_rebalance: indices_all_active
      enable: all
      node_concurrent_recoveries: 2
      cluster_concurrent_rebalance: 2
      disk:
        threshold_enabled: true
        watermark:
          flood_stage: 0.97
          low: 0.85
          high: 0.9
    rebalance:
      enable: all
  info:
    update:
      interval: 1m

# Force all memory to be locked, forcing the JVM to never swap
bootstrap.memory_lock: true

## thread_pool Settings ##
thread_pool:
  search:
    queue_size: 1000
  write:
    queue_size: 10000

# Indices settings
indices.memory.index_buffer_size: 30%
indices.memory.min_index_buffer_size: 96mb

# Cache Sizes
indices.fielddata.cache.size: 30%
indices.queries.cache.size: 15%

# Unicast Discovery
discovery.seed_hosts:
  - new-neo-hot-1
  - new-neo-hot-2
  - new-neo-hot-3

# X-PACK Security settings
# Set Watcher (disabled)
xpack.watcher.enabled: false
# Set Machine learning (disabled)
xpack.ml.enabled: false

## License
xpack.license.self_generated.type: basic

# Enable security features
xpack.security.enabled: true
xpack.security.enrollment.enabled: true

# Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12

# Enable encryption and mutual authentication between cluster nodes
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
```

Run service elasticsearch

```
systemctl start elasticsearch
systemctl enable elasticsearch
systemctl status elasticsearch
```

# In ES - NODE 03

```
# Enter node key to join cluster node:
/usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token [Enter-node-key-03 generated]

# Config ES
vi elasticsearch.yml
====================


# Cluster / Node Basics
cluster.name: new-neo-cluster

# Node can have abritrary attributes we can use for routing
node.name: new-neo-hot-2

# Node type
node.roles: ["master", "data", "data_hot"]

# Network
network.host: 0.0.0.0
http.port: 59701

transport.host: 0.0.0.0

# Path node
path.logs: /var/log/elasticsearch
path.data: /var/lib/elasticsearch
path.repo: ["/usr/share/elasticsearch/backup"]

# Content sizing of an HTTP request
http.max_content_length: 300mb
http.max_initial_line_length: 100kb

# Cluster routing
# Handle disk to relocate shards away from a node
#cluster.routing.allocation.enable - disable/enable shard allocation (all-default)
#cluster.routing.allocation.disk.threshold_enabled- disk allocation decider
#cluster.info.update.interval- disk usage check interval
cluster:
  routing:
    allocation:
      allow_rebalance: indices_all_active
      enable: all
      node_concurrent_recoveries: 2
      cluster_concurrent_rebalance: 2
      disk:
        threshold_enabled: true
        watermark:
          flood_stage: 0.97
          low: 0.85
          high: 0.9
    rebalance:
      enable: all
  info:
    update:
      interval: 1m

# Force all memory to be locked, forcing the JVM to never swap
bootstrap.memory_lock: true

## thread_pool Settings ##
thread_pool:
  search:
    queue_size: 1000
  write:
    queue_size: 10000

# Indices settings
indices.memory.index_buffer_size: 30%
indices.memory.min_index_buffer_size: 96mb

# Cache Sizes
indices.fielddata.cache.size: 30%
indices.queries.cache.size: 15%

# Unicast Discovery
discovery.seed_hosts:
  - new-neo-hot-1
  - new-neo-hot-2
  - new-neo-hot-3

# X-PACK Security settings
# Set Watcher (disabled)
xpack.watcher.enabled: false
# Set Machine learning (disabled)
xpack.ml.enabled: false

## License
xpack.license.self_generated.type: basic

# Enable security features
xpack.security.enabled: true
xpack.security.enrollment.enabled: true

# Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12

# Enable encryption and mutual authentication between cluster nodes
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
```

Run service elasticsearch

```
systemctl start elasticsearch
systemctl enable elasticsearch
systemctl status elasticsearch
```

In ES - NODE 01
Restart to update service elasticsearch

```
systemctl start elasticsearch
systemctl enable elasticsearch
systemctl status elasticsearch
```

```
Test connection:
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:QeH-l7APlcV6GFadcXu0 https://localhost:59701

curl --cacert /etc/elasticsearch/certs/elastic.pem -u elastic:LKUI=26IgAsiY*RXng*R https://localhost:59701/_cat/nodes?v

curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:LKUI=26IgAsiY*RXng*R https://localhost:59701/_cat/nodes?v
```

Cerebro

======================
https://e-mc2.net/access-elasticsearch-cerebro-sslldap
https://github.com/lmenezes/cerebro

Download and Rename folder to /etc/cerebro

```
wget https://github.com/lmenezes/cerebro/releases/download/v0.9.4/cerebro-0.9.4.zip

unzip cerebro-0.9.4.zip
mv cerebro-0.9.4 /etc/cerebro
```

Edit hostname at: /etc/cerebro/conf/application.conf

```
hosts = [
{
    host = "https://localhost:59701"
    name = "ES PRODUCTION"
    auth = {
      username = "elastic"
      password = "pass"
    }
}
]

play.ws.ssl {
  trustManager = {
    stores = [
      { type = "PEM", path = "/etc/elasticsearch/certs/elastic.pem" }
    ]
  }
}
play.ws.ssl.loose.acceptAnyCertificate=true
```

Configure SElinux with these commands.

```
# semanage port -a -t http_port_t -p tcp 59701
# setsebool -P httpd_can_network_connect 1
# setsebool -P nis_enabled 1
```

Create the file '/etc/systemd/system/cerebro.service' with this content:

```
vi /etc/systemd/system/cerebro.service

[Unit]
Description=Elasticsearch - Cerebro
Wants=network-online.target
After=network-online.target

[Service]
Environment=HOST=127.0.0.1
Environment=PORT=5972
WorkingDirectory=/etc/cerebro
User=root
Group=root
ExecStart=/etc/cerebro/bin/cerebro \
                                        -Dhttp.port=${PORT} \
                                        -Dhttp.address=${HOST}

# Connects standard output to /dev/null
StandardOutput=null

# Connects standard error to journal
StandardError=journal

# Shutdown delay in seconds, before process is tried to be killed with KILL (if configured)
TimeoutStopSec=0

# SIGTERM signal is used to stop the Java process
KillSignal=SIGTERM

# Java process is never killed
SendSIGKILL=no

# When a JVM receives a SIGTERM signal it exits with code 143
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
```

Start cerebro service

```
systemctl daemon-reload

systemctl start cerebro
systemctl status cerebro
systemctl enable cerebro
```

Install Kibana
==================

```
cd /opt

wget https://artifacts.elastic.co/downloads/kibana/kibana-8.8.0-x86_64.rpm
wget https://artifacts.elastic.co/downloads/kibana/kibana-8.8.0-x86_64.rpm.sha512
shasum -a 512 -c kibana-8.8.0-x86_64.rpm.sha512
sudo rpm --install kibana-8.8.0-x86_64.rpm
```

```
# Generate token - key for Kibana
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana

# Enroll
/usr/share/kibana/bin/kibana-setup --enrollment-token eyJ2ZXIiOiI4LjguMCIsImFkciI6WyIxMzkuNTkuMTIxLjE0Mjo1OTcwMSJdLCJmZ3IiOiJmMDdlZjJmMzJkMjdhYjY5MjJhMzcyM2M4ZmE4YTI3ZDRjNWVmOTRjODEzZjM1YTUyODU5NGI2ZjlkYTc5NWExIiwia2V5IjoieEtkV2JJZ0JRNk5wemRfeWUwWUk6eHRyRU5RN1hSa202VGVlb21CMkRZQSJ9
```

```
# Set permission:
chown -R kibana:kibana /var/log/kibana

# Config host - port
vim /etc/kibana/kibana.yml

server.host: "0.0.0.0"
server.port: 5971
server.name: "Kibana"
```

```
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana --url https://localhost:59701
New value: lYBsf6Yqcy7wYegOkJhu

/usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system --url https://localhost:59701
New value: wPmsnA8Wz5j3y1G-6CJ9
```

---

Logstash

Add the following in your /etc/yum.repos.d/ directory in a file with a .repo suffix, for example logstash.repo

```
[logstash-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

And your repository is ready for use. You can install it with:

```
sudo yum install logstash
```

Start logstash

```
service logstash start

cd /usr/share/logstash
bin/logstash-plugin install logstash-input-mongodb
mkdir logstash-mongodb
```

```
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u logstash_system --url https://localhost:59701
New value: KS8*Y2fSi*MRpKdNaPdB
```

https://www.elastic.co/blog/configuring-ssl-tls-and-https-to-secure-elasticsearch-kibana-beats-and-logstash

```
POST /_security/role/logstash_write_role
{
    "cluster": [
      "monitor",
      "manage_index_templates"
    ],
    "indices": [
      {
        "names": [
          "logstash*"
        ],
        "privileges": [
          "write",
          "create_index"
        ],
        "field_security": {
          "grant": [
            "*"
          ]
        }
      }
    ],
    "run_as": [],
    "metadata": {},
    "transient_metadata": {
      "enabled": true
    }
}

POST /_security/user/logstash_writer
{
  "username": "logstash_writer",
  "roles": [
    "logstash_write_role"
  ],
  "full_name": null,
  "email": null,
  "password": "Y2fSiMRpKdNaPdB",
  "enabled": true
}
```
