# roles/<NOM_ROLE>/templates/compose.<NOM_SERVICE>.yml.j2

Un fichier par service. Secrets = `${VARIABLE}` lus dans le `.env` (jamais en dur).

## Base de données (MySQL / MariaDB) — aucun port publié

```yaml
services:
  <NOM_SERVICE_DB>:                 # ex: mysql
    image: <IMAGE_DB>:<TAG>         # ex: mysql:8.0 / mariadb:11
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - <NOM_VOLUME_DB>:/var/lib/mysql
    networks:
      - <NOM_RESEAU>
    # pas de "ports:" -> joignable seulement sur le réseau docker (3306)
```

## Application PHP-FPM (ex: WordPress) + conteneur outil (profile)

```yaml
services:
  <NOM_SERVICE_APP>:                # ex: wordpress
    image: <IMAGE_APP>:<TAG>        # ex: wordpress:php8.1-fpm
    restart: always
    depends_on:
      - <NOM_SERVICE_DB>
    environment:
      WORDPRESS_DB_HOST: <NOM_SERVICE_DB>
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - <NOM_VOLUME_APP>:/var/www/html
    networks:
      - <NOM_RESEAU>

  <NOM_SERVICE_OUTIL>:              # ex: wpcli
    image: <IMAGE_OUTIL>:<TAG>      # ex: wordpress:cli
    profiles:
      - tools                       # ne démarre PAS avec "docker compose up"
    depends_on:
      - <NOM_SERVICE_DB>
      - <NOM_SERVICE_APP>
    environment:
      WORDPRESS_DB_HOST: <NOM_SERVICE_DB>
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - <NOM_VOLUME_APP>:/var/www/html
    networks:
      - <NOM_RESEAU>
    user: "33:33"                   # www-data, même user que php-fpm
```

## Interface admin derrière le proxy (ex: phpMyAdmin)

```yaml
services:
  <NOM_SERVICE_ADMIN>:              # ex: phpmyadmin
    image: <IMAGE_ADMIN>:<TAG>      # ex: phpmyadmin:latest
    restart: always
    depends_on:
      - <NOM_SERVICE_DB>
    environment:
      PMA_HOST: <NOM_SERVICE_DB>
      PMA_PORT: "3306"
      PMA_ABSOLUTE_URI: https://{{ ansible_host }}{% if https_port | int != 443 %}:{{ https_port }}{% endif %}/<CHEMIN_URL>/
    networks:
      - <NOM_RESEAU>
    # pas de ports : accessible uniquement via nginx
```

## Reverse proxy nginx — le SEUL service qui publie des ports

```yaml
services:
  nginx:
    image: nginx:alpine
    restart: always
    depends_on:
      - <NOM_SERVICE_APP>
      - <NOM_SERVICE_ADMIN>
    ports:
      - "{{ http_port }}:80"
      - "{{ https_port }}:443"
    volumes:
      - {{ project_dir }}/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - {{ project_dir }}/ssl:/etc/nginx/ssl:ro
      - <NOM_VOLUME_APP>:/var/www/html        # nginx sert les fichiers statiques
    networks:
      - <NOM_RESEAU>
```

## Rappels Jinja2 dans les .j2

| Syntaxe | Sens |
|---|---|
| `{{ var }}` | remplacé par Ansible (au déploiement) |
| `${VAR}` | remplacé par docker compose (depuis `.env`) |
| `{% if cond %}...{% endif %}` | condition |
| `{% for x in liste %}...{% endfor %}` | boucle |
| `{{ liste \| join(':') }}` | filtre |
| `{{ var \| default('x') }}` | valeur par défaut |
| `{# commentaire #}` | commentaire Jinja (absent du fichier final) |
