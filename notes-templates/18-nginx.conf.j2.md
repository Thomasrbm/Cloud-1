# roles/proxy/templates/nginx.conf.j2

- Seule porte d'entrée du serveur
- HTTP → HTTPS, TLS, sous-chemin vers un autre conteneur, PHP vers php-fpm

```nginx
# ==============================================================================
# BLOC 1 : HTTP -> redirection vers HTTPS
# nginx choisit le bloc server selon le port et le nom demandés
# ==============================================================================
server {
    # écoute le port 80 ; bloc utilisé si aucun autre ne correspond
    listen 80 default_server;

    # accepte n'importe quel nom ou IP
    server_name _;

    # 301 = redirection définitive
    # $host = nom/IP tapé par le visiteur
    # le {% if %} ajoute ":port" seulement si HTTPS n'est pas sur 443
    # $request_uri = chemin demandé, conservé (ex : /contact)
    return 301 https://$host{% if https_port | int != 443 %}:{{ https_port }}{% endif %}$request_uri;
}


# ==============================================================================
# BLOC 2 : le site en HTTPS
# ==============================================================================
server {
    # écoute le port 443 avec chiffrement TLS
    listen 443 ssl default_server;
    server_name _;

    # certificat public + clé privée (montés depuis <PROJECT_DIR>/ssl)
    ssl_certificate     /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # versions de TLS autorisées, les anciennes sont refusées
    ssl_protocols       TLSv1.2 TLSv1.3;

    # dossier des fichiers du site (volume partagé avec l'application)
    root /var/www/html;

    # fichier ouvert quand on demande un dossier
    index index.php index.html;


    # --- page de test (facultatif) : prouve que le déploiement est à jour ---
    # location = /<CHEMIN_TEST> {
    #     default_type text/html;
    #     return 200 '<h1>Deploye par Ansible</h1>';
    # }


    # --- sous-chemin vers un autre conteneur (ex : phpMyAdmin) ---

    # adresse exacte sans "/" final -> redirigée vers la version avec "/"
    location = /<CHEMIN_URL> {
        return 301 /<CHEMIN_URL>/;
    }

    # ^~ = tout ce qui commence par /<CHEMIN_URL>/ (prioritaire sur les regex)
    location ^~ /<CHEMIN_URL>/ {
        # transmet au conteneur, joint par son nom de service
        # le "/" final retire /<CHEMIN_URL> avant de transmettre
        proxy_pass http://<NOM_SERVICE_ADMIN>:<PORT_CONTENEUR>/;

        # nom demandé par le visiteur
        proxy_set_header Host              $host;
        # IP du visiteur
        proxy_set_header X-Real-IP         $remote_addr;
        # liste des IP traversées (visiteur + proxys)
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        # indique au conteneur que le visiteur est en HTTPS
        proxy_set_header X-Forwarded-Proto $scheme;
    }


    # --- application PHP (ex : WordPress) ---

    # tout ce qui n'a pas été attrapé avant
    # sert le fichier s'il existe, sinon le dossier, sinon index.php (URLs propres)
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # toute URL qui finit par .php
    location ~ \.php$ {
        # envoie le script à php-fpm (nom du conteneur, port 9000 par défaut)
        fastcgi_pass <NOM_SERVICE_APP>:9000;

        # script lancé si l'URL finit par "/"
        fastcgi_index index.php;

        # transmet les infos standard de la requête (méthode, en-têtes...)
        include fastcgi_params;

        # chemin complet du fichier PHP à exécuter
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        # dit à PHP que le site est en HTTPS (sinon WordPress redirige en boucle)
        fastcgi_param HTTPS on;
    }
}
```

## Variante : proxy vers une appli HTTP (Node, Python...)

```nginx
location / {
    # adresse de l'appli (nom du service + son port)
    proxy_pass http://<NOM_SERVICE_APP>:<PORT_APP>;

    # nécessaire pour les websockets
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Types de location

- `location = /x` : exactement `/x`
- `location ^~ /x/` : commence par `/x/`, prioritaire sur les regex
- `location ~ regex` : regex sensible à la casse
- `location ~* regex` : regex insensible à la casse
- `location /` : tout le reste

## Tester

```bash
# vérifie la syntaxe de la config dans le conteneur
docker compose exec nginx nginx -t

# interroge le site (-k accepte le certificat auto-signé, -I = en-têtes seulement)
curl -kI https://<IP_SERVEUR>/
```
