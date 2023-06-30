## Fix redis server startup warnings, redis tuning performance
- https://success.outsystems.com/documentation/how_to_guides/infrastructure/configuring_outsystems_with_redis_in_memory_session_storage/set_up_a_redis_cluster_for_production_environments/

- **Maximum Open Files**

```
You requested maxclients of 10000 requiring at least 10032 max file descriptors.
Server can't set maximum open files to 10032 because of OS error: Operation not permitted.
Current maximum open files is 4096. maxclients has been reduced to 4064 to compensate for maxclients has been reduced to 4064 to compensate for low ulimit. If you need higher maxclients increase 'ulimit -n'.
```

_Solution:_

Update system file, add at the bottom of file:

```Shell
$ sudo vim /etc/sysctl.conf

vm.overcommit_memory = 1
net.core.somaxconn=65535
fs.file-max = 100000
```

```Shell
$ sudo vim /etc/security/limits.conf

*          soft nproc          100000
*          hard nproc          100000
*          soft nofile         100000
*          hard nofile         100000
```

Now for these configs to work, you need to reload the config

```
$ sudo sysctl -p
```

At root user, Set user soft and hard limits as follows:

```
ulimit -n 100000
ulimit -u 100000
ulimit -a
```

- **Transparent Huge Pages**

```Shell
WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
```

_Solution:_

To permanently solve this, follow the log's suggestion, and modify rc.local:
`sudo vi /etc/rc.local`

```Shell
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
```

This require you to reboot, backup your data or do anything you need before you actually do it!!

`sudo reboot`

Run the command as root:

```
$ echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

Now check you redis log again, you should have a redis server without any errors or warnings.

Check status:

```Shell
$ cat  /sys/kernel/mm/transparent_hugepage/enabled
> always madvise [never]
```
