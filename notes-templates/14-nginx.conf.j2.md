# roles/proxy/templates/nginx.conf.j2

Reverse proxy : HTTP→HTTPS, TLS, sous-chemin vers un conteneur, PHP via php-fpm.

```nginx
# HTTP -> redirection HTTPS
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host{% if https_port | int != 443 %}:{{ https_port }}{% endif %}$request_uri;
}

server {
    listen 443 ssl default_server;
    server_name _;                          # ou {{ domain_name }}

    ssl_certificate     /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php index.html;

    # Page de test (preuve de déploiement)
    # location = /<CHEMIN_TEST> {
    #     default_type text/html;
    #     return 200 '<h1>Deploye par Ansible</h1>';
    # }

    # --- Sous-chemin vers un autre conteneur (ex: phpMyAdmin) ---
    location = /<CHEMIN_URL> {
        return 301 /<CHEMIN_URL>/;
    }

    location ^~ /<CHEMIN_URL>/ {
        proxy_pass http://<NOM_SERVICE_ADMIN>:<PORT_CONTENEUR>/;   # nom du service docker
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # --- Application PHP (ex: WordPress) ---
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass <NOM_SERVICE_APP>:9000;      # php-fpm
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;                   # évite les boucles de redirection
    }
}
```

## Variante : proxy vers une app HTTP (Node, Python...)

```nginx
location / {
    proxy_pass http://<NOM_SERVICE_APP>:<PORT_APP>;
    proxy_http_version 1.1;
    proxy_set_header Upgrade    $http_upgrade;   # websockets
    proxy_set_header Connection "upgrade";
    proxy_set_header Host       $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Types de `location`

| Syntaxe | Match |
|---|---|
| `location = /x` | exactement `/x` |
| `location ^~ /x/` | commence par `/x/` (prioritaire sur les regex) |
| `location ~ \.php$` | regex sensible à la casse |
| `location ~* \.(jpg\|png)$` | regex insensible à la casse |
| `location /` | tout le reste |

## Tester

```sh
docker compose exec nginx nginx -t
curl -kI https://<IP_SERVEUR>/
```
