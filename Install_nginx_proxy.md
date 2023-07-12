## Installing Nginx on CentOS

Follow the steps below to install Nginx on your CentOS server:

- 1. Nginx packages are available in the EPEL repositories.
     If you don’t have EPEL repository already installed you can do it by typing:

`$ sudo yum install epel-release`

- 2. Install Nginx by typing the following yum command:
     `$ sudo yum install nginx`
     > If this is the first time you are installing a package from the EPEL repository, yum may prompt you to import the EPEL GPG key:

`Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
Importing GPG key 0x352C64E5:
Userid     : "Fedora EPEL (7) <epel@fedoraproject.org>"
Fingerprint: 91e9 7d7c 4a5e 96f1 7f3e 888f 6a2f aea2 352c 64e5
Package    : epel-release-7-9.noarch (@extras)
From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
Is this ok [y/N]:`

> If that’s the case, type y and hit Enter.

- 3. Once the installation is complete, enable and start the Nginx service with:

`$ sudo systemctl enable nginx` <br />
`$ sudo systemctl start nginx`

> Check the status of the Nginx service with the following command:

`$ sudo systemctl status nginx`

`● nginx.service - The nginx HTTP and reverse proxy server
  Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
  Active: active (running) since Mon 2018-03-12 16:12:48 UTC; 2s ago
  Process: 1677 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 1675 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 1673 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
Main PID: 1680 (nginx)
  CGroup: /system.slice/nginx.service
          ├─1680 nginx: master process /usr/sbin/nginx
          └─1681 nginx: worker process
`

- 4. If your server is protected by a firewall you need to open both HTTP (80) and HTTPS (443) ports.

> Use the following commands to open the necessary ports:

`$ sudo firewall-cmd --permanent --zone=public --add-service=http`<br />
`$ sudo firewall-cmd --permanent --zone=public --add-service=https`<br />
`$ sudo firewall-cmd --reload`

> To verify your Nginx installation, open http://YOUR_IP in your browser of choice, and you will see the default Nginx welcome page.

### Manage the Nginx Service with systemctl

You can manage the Nginx service in the same way as any other systemd unit.

To stop the Nginx service, run:

`$ sudo systemctl stop nginx`

To start it again, type:

`$ sudo systemctl start nginx`

To restart the Nginx service:

`$ sudo systemctl restart nginx`

Reload the Nginx service after you have made some configuration changes:

`$ sudo systemctl reload nginx`

If you want to disable the Nginx service to start at boot:

`$ sudo systemctl disable nginx`

And to re-enable it again:

`$ sudo systemctl enable nginx`

### Nginx Configuration File’s Structure and Best Practices

> All Nginx configuration files are located in the /etc/nginx/ directory.<br />
> The main Nginx configuration file is /etc/nginx/nginx.conf.<br />
> To make Nginx configuration easier to maintain it is recommended to create a separate configuration file for each domain.<br />
> New Nginx server block files must end with .conf and be stored in /etc/nginx/conf.d directory. You can have as many server blocks as you need.<br />
> It is a good idea to follow a standard naming convention, for example if your domain name is mydomain.com then your configuration file should be named /etc/nginx/conf.d/mydomain.com.conf<br />
> If you use repeatable configuration segments in your domains server blocks then it is a good idea to create a directory named /etc/nginx/snippets refactoring those segments into snippets and include the snippet file to the server blocks.<br />
> Nginx log files (access.log and error.log) are located in the /var/log/nginx/ directory. It is recommended to have a different access and error log files for each server block.<br />
> You can set your domain document root directory to any location you want. The most common locations for webroot include:<br />
> `/home/<user_name>/<site_name>`<br />
> `/var/www/<site_name>`<br />
> `/var/www/html/<site_name>`<br />
> `/opt/<site_name>`<br />
> `/usr/share/nginx/html`

> source: [Linuxize](https://linuxize.com/post/how-to-install-nginx-on-centos-7/#manage-the-nginx-service-with-systemctl)
