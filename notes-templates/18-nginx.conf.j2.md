# roles/proxy/templates/nginx.conf.j2

## À quoi ça sert

nginx est la seule porte d'entrée du serveur. Il :

- redirige HTTP vers HTTPS
- chiffre avec le certificat TLS
- envoie `/<CHEMIN_URL>/` vers un autre conteneur (ex : phpMyAdmin)
- envoie les fichiers `.php` à php-fpm
- sert directement les images et le CSS

## Bloc 1 : redirection HTTP vers HTTPS

```nginx
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host{% if https_port | int != 443 %}:{{ https_port }}{% endif %}$request_uri;
}
```

- `server { }` : un site. nginx choisit le bloc selon le port et le nom demandés
- `listen 80 default_server` : écoute le port 80 (HTTP). Bloc utilisé si aucun autre ne correspond
- `server_name _` : accepte n'importe quel nom ou IP
- `return 301` : redirection définitive
- `$host` : nom ou IP tapé par le visiteur
- `{% if ... %}` : ajoute `:port` seulement si HTTPS n'est pas sur 443
- `$request_uri` : chemin demandé, conservé (ex : `/contact`)

## Bloc 2 : le site en HTTPS

```nginx
server {
    listen 443 ssl default_server;
    server_name _;

    ssl_certificate     /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php index.html;
```

- `listen 443 ssl` : écoute le port 443 avec chiffrement TLS
- `ssl_certificate` : certificat public, monté depuis `<PROJECT_DIR>/ssl`
- `ssl_certificate_key` : clé privée du certificat
- `ssl_protocols` : versions de TLS autorisées, les anciennes sont refusées
- `root` : dossier des fichiers du site (le volume partagé avec l'application)
- `index` : fichier ouvert quand on demande un dossier

## Sous-chemin vers un autre conteneur (ex : phpMyAdmin)

```nginx
    location = /<CHEMIN_URL> {
        return 301 /<CHEMIN_URL>/;
    }

    location ^~ /<CHEMIN_URL>/ {
        proxy_pass http://<NOM_SERVICE_ADMIN>:<PORT_CONTENEUR>/;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
```

- `location = /<CHEMIN_URL>` : adresse exacte sans `/` final, redirigée vers la version avec `/`
- `location ^~ /<CHEMIN_URL>/` : tout ce qui commence par ce chemin
- `proxy_pass` : transmet la requête au conteneur, joint par son nom de service
- `/` final de `proxy_pass` : retire `/<CHEMIN_URL>` avant de transmettre
- `Host` : nom demandé par le visiteur
- `X-Real-IP` : IP du visiteur
- `X-Forwarded-For` : liste des IP traversées (visiteur + proxys)
- `X-Forwarded-Proto` : indique au conteneur que le visiteur est en HTTPS

## Application PHP (ex : WordPress)

```nginx
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass <NOM_SERVICE_APP>:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
    }
}
```

- `location /` : tout ce qui n'a pas été attrapé avant
- `try_files` : sert le fichier s'il existe, sinon le dossier, sinon passe la main à `index.php` (URLs propres de WordPress)
- `location ~ \.php$` : toute URL qui finit par `.php`
- `fastcgi_pass <NOM_SERVICE_APP>:9000` : envoie le script à php-fpm (port 9000 par défaut)
- `fastcgi_index` : script lancé si l'URL finit par `/`
- `include fastcgi_params` : transmet les infos standard de la requête (méthode, en-têtes...)
- `SCRIPT_FILENAME` : chemin complet du fichier PHP à exécuter
- `HTTPS on` : dit à PHP que le site est en HTTPS, sinon WordPress redirige en boucle
- `}` final : ferme le bloc `server` du port 443

## Page de test (facultatif)

```nginx
    location = /<CHEMIN_TEST> {
        default_type text/html;
        return 200 '<h1>Deploye par Ansible</h1>';
    }
```

- Renvoie directement du HTML, utile pour prouver que le déploiement est à jour. À mettre dans le bloc 443.

## Variante : proxy vers une appli HTTP (Node, Python...)

```nginx
    location / {
        proxy_pass http://<NOM_SERVICE_APP>:<PORT_APP>;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
```

- `proxy_http_version 1.1` : nécessaire pour les websockets
- `Upgrade` / `Connection` : laissent passer les websockets

## Les types de location

- `location = /x` : exactement `/x`
- `location ^~ /x/` : commence par `/x/`, prioritaire sur les regex
- `location ~ regex` : expression régulière, sensible à la casse
- `location ~* regex` : expression régulière, insensible à la casse
- `location /` : tout le reste

## Tester

```bash
docker compose exec nginx nginx -t
```

- Vérifie la syntaxe de la config dans le conteneur.

```bash
curl -kI https://<IP_SERVEUR>/
```

- Interroge le site en HTTPS. `-k` accepte le certificat auto-signé, `-I` affiche seulement les en-têtes.
