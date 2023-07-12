## Install Keepalived

```
$ sudo yum groupinstall -y "Development Tools"
$ sudo yum install -y gcc kernel-headers kernel-devel curl gcc openssl-devel libnl3-devel net-snmp-devel psmisc ipset-libs
$ sudo yum install -y keepalived
```

### Manage the Keepalived Service with systemctl

You can manage the Keepalived service in the same way as any other systemd unit.

To stop the Keepalived service, run:

`$ sudo systemctl stop keepalived`

To start it again, type:

`$ sudo systemctl start keepalived`

To restart the Keepalived service:

`$ sudo systemctl restart keepalived`

Reload the Keepalived service after you have made some configuration changes:

`$ sudo systemctl reload keepalived`

If you want to disable the Keepalived service to start at boot:

`$ sudo systemctl disable keepalived`

And to re-enable it again:

`$ sudo systemctl enable keepalived`

### Keepalived Configuration System

Add config below into file sysctl.conf

> vim /etc/sysctl.conf

```
fs.inotify.max_user_watches=524288
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1

net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 1
net.ipv4.conf.all.arp_filter = 0
```

Check sysctl file:

> sysctl -p
