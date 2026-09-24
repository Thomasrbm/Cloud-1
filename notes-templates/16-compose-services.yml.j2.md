# roles/<NOM_ROLE>/templates/compose.<NOM_SERVICE>.yml.j2

## À quoi ça sert

Un fichier par service. Les mots de passe sont écrits `${VARIABLE}` : docker compose les lit dans le `.env`, ils ne sont jamais écrits en dur.

## Base de données (MySQL / MariaDB)

```yaml
services:
  <NOM_SERVICE_DB>:
    image: <IMAGE_DB>:<TAG>
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
```

- `<NOM_SERVICE_DB>` : nom du service, sert aussi d'adresse sur le réseau (ex : `mysql`)
- `image:` : ex `mysql:8.0` ou `mariadb:11`
- `MYSQL_ROOT_PASSWORD` : mot de passe root de la base
- `MYSQL_DATABASE` : base créée au premier démarrage
- `MYSQL_USER` / `MYSQL_PASSWORD` : compte créé pour l'application
- `/var/lib/mysql` : dossier où MySQL range ses données, sauvegardé dans le volume
- Pas de `ports:` : la base n'est jamais joignable depuis Internet, seulement sur le réseau docker

## Application PHP-FPM (ex : WordPress)

```yaml
services:
  <NOM_SERVICE_APP>:
    image: <IMAGE_APP>:<TAG>
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
```

- `image:` : ex `wordpress:php8.1-fpm`, PHP sans serveur web (nginx s'en charge)
- `depends_on:` : démarre la base avant l'application
- `WORDPRESS_DB_HOST` : adresse de la base = nom de son service
- `WORDPRESS_DB_NAME` / `_USER` / `_PASSWORD` : identifiants de la base, repris du `.env`
- `/var/www/html` : fichiers du site, dans un volume pour survivre au reboot

## Conteneur outil lancé à la demande (ex : wp-cli)

```yaml
services:
  <NOM_SERVICE_OUTIL>:
    image: <IMAGE_OUTIL>:<TAG>
    profiles:
      - tools
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
    user: "33:33"
```

- `image:` : ex `wordpress:cli`
- `profiles: [tools]` : ne démarre pas avec `docker compose up`, seulement avec `--profile tools run`
- Même volume que l'application : l'outil voit et modifie les mêmes fichiers
- `user: "33:33"` : tourne en `www-data`, le même utilisateur que php-fpm, pour ne pas casser les droits

## Interface d'administration derrière le proxy (ex : phpMyAdmin)

```yaml
services:
  <NOM_SERVICE_ADMIN>:
    image: <IMAGE_ADMIN>:<TAG>
    restart: always
    depends_on:
      - <NOM_SERVICE_DB>
    environment:
      PMA_HOST: <NOM_SERVICE_DB>
      PMA_PORT: "3306"
      PMA_ABSOLUTE_URI: https://{{ ansible_host }}{% if https_port | int != 443 %}:{{ https_port }}{% endif %}/<CHEMIN_URL>/
    networks:
      - <NOM_RESEAU>
```

- `image:` : ex `phpmyadmin:latest`
- `PMA_HOST` : adresse de la base
- `PMA_PORT` : port de la base
- `PMA_ABSOLUTE_URI` : URL publique complète, pour que les liens marchent derrière nginx sous `/<CHEMIN_URL>/`
- `{% if ... %}:{{ https_port }}{% endif %}` : ajoute le port dans l'URL seulement s'il n'est pas 443
- Pas de `ports:` : accessible uniquement via nginx

## Reverse proxy nginx (le seul exposé)

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
      - <NOM_VOLUME_APP>:/var/www/html
    networks:
      - <NOM_RESEAU>
```

- `nginx:alpine` : image nginx légère
- `ports:` : seul service qui publie des ports sur le serveur (80 et 443)
- 1er volume : la config nginx générée par Ansible, montée à la place de la config par défaut
- 2e volume : le dossier des certificats TLS
- `:ro` : lecture seule, le conteneur ne peut pas les modifier
- 3e volume : les fichiers du site, pour que nginx serve les images et le CSS sans passer par PHP

## Les deux types de variables dans un .j2

- `{{ variable }}` : remplacée par Ansible au moment du déploiement
- `${VARIABLE}` : laissée telle quelle par Ansible, remplacée par docker compose avec le `.env`
- `{% if condition %} ... {% endif %}` : condition Jinja
- `{% for x in liste %} ... {% endfor %}` : boucle Jinja
- `{{ liste | join(':') }}` : filtre qui colle les éléments avec `:`
- `{{ variable | default('x') }}` : valeur par défaut si la variable n'existe pas
- `{# texte #}` : commentaire Jinja, absent du fichier final
