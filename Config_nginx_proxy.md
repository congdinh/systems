## Config NGINX Proxy

- Find status of Nginx server command

```$ sudo service nginx status```

- Configure Nginx server:
> Config dir – /etc/nginx/<br/>
> Master/Global config file – /etc/nginx/nginx.conf<br/>
> Port 80 http config file – /etc/nginx/conf.d/default<br/>
> TCP ports opened by Nginx – 80 (HTTP), 443 (HTTPS)<br/>
> Document root directory – /usr/share/nginx/html<br/>
- To edit files use a text editor such as vi

```$ sudo vi /etc/nginx/conf.d/your-domain.conf```

- After config, save and test syntax nginx:

```$ nginx -t```

- If ok, you can restart nginx that apply changed.

```$ sudo service nginx restart```

### Create a new file specifically for the server block for the yourdomain.com site

- Simple config:

```
server {
   listen 80;
   server_name yourdomain.com www.yourdomain.com;

   location / {
      root /var/www/yourdomain.com/public_html;
      index index.html index.htm;
      try_files $uri $uri/ =404;
   }

   error_page 500 502 503 504 /50x.html;
   location = /50x.html {
      root html;
   }
}
```

- Config with port and domain xxx;

```
######################## http.conf ######################
server {
  listen 80;
  server_name xxx.com;

  access_log /var/log/nginx/xxx.access.log main;
  error_log /var/log/nginx/xxx.error.log error;

  root /opt;
  location / {
    proxy_pass http://127.0.0.1:port_service/;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_read_timeout 300s;
    proxy_cache_bypass $http_upgrade;
  }
}
```

- Config with SSL and let's encrypt:

```
######################## SSL xxx.conf ######################

server {
  listen 443 ssl http2;
  server_name xxx.com;
  ssl_certificate /etc/letsencrypt/live/xxx.vn/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/xxx.vn/privkey.pem;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;

  #Improve HTTPS performance with session resumption
  ssl_session_cache shared:SSL:50m;
  ssl_session_timeout 1d;

  #DH parameters
  ssl_dhparam /etc/nginx/ssl/dhparam.pem;
  #Enable HSTS
  add_header Strict-Transport-Security "max-age=31536000" always;

  access_log /var/log/nginx/xxx.com.access.log main;
  error_log /var/log/nginx/xxx.com.error.log error;

  root /opt;
  location / {
    proxy_pass http://127.0.0.1:port;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_read_timeout 300s;
    proxy_cache_bypass $http_upgrade;
  }
  location /install_sensu {
    try_files $uri /install_sensu.sh;
  }
}

# auto redirect http to https
server {
  listen 80;
  server_name xxx.com;
  rewrite ^(.*) https://xxx.com$1 permanent;
}
```

