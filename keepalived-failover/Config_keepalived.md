## Configuration Keepalived Service

- Simple config for 2 server with 1 Virtual IP using NGINX.

Remove all content and update new config at:` /etc/keepalived/keepalived.conf`

> Node Master

```
# web-server 1
global_defs {
  # Keepalived process identifier
  # lvs_id nginx_DH
}
# Script used to check if Nginx is running
vrrp_script check_nginx {
  script "/usr/sbin/pidof nginx"
  interval 2
  weight 4
}
# Virtual interface
# The priority specifies the order in which the assigned interface to take over in a failover
vrrp_instance VI_01 {
  state MASTER
  interface wlp3s0
  mcast_src_ip 192.168.1.111
  virtual_router_id 50
  priority 100
  # nopreempt
  advert_int 1
  # The virtual ip address shared between the two loadbalancers
  virtual_ipaddress {
    192.168.1.100
  }
  track_script {
    check_nginx
  }
}
```

> Node Backup

```

# web-server 2
global_defs {
  # Keepalived process identifier
  # lvs_id nginx_DH
}
# Script used to check if Nginx is running
vrrp_script check_nginx {
  script "/usr/sbin/pidof nginx"
  interval 2
  weight 4
}
# Virtual interface
# The priority specifies the order in which the assigned interface to take over in a failover
vrrp_instance VI_01 {
  state BACKUP
  mcast_src_ip 192.168.1.112
  interface wlp3s0
  virtual_router_id 50
  priority 98
  # nopreempt
  advert_int 1
  # The virtual ip address shared between the two loadbalancers
  virtual_ipaddress {
    192.168.1.100
  }
  track_script {
    check_nginx
  }
}
```

interface: You need change this field with your network card:

> Get your network card that using command: $ ifconfig

mcast_src_ip: This is your current IP server.
virtual_ipaddress: The virtual ip address shared between the two loadbalancers.

- Check Virtual IP added to your network card:

  > $ ip a sh wlp3s0

- Check logs at: /var/log/messages

[Detail at here](https://cuongquach.com/cau-hinh-keepalived-thuc-hien-ip-failover-he-thong-ha.html)
