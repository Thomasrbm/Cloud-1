# roles/<NOM_ROLE>/templates/compose.<NOM_SERVICE>.yml.j2

- Un fichier par service
- `{{ variable }}` : remplacée par Ansible au déploiement
- `${VARIABLE}` : laissée par Ansible, remplacée par docker compose depuis le `.env`

## compose.db.yml.j2 (MySQL / MariaDB)

```yaml
services:
  # nom du service = son adresse sur le réseau docker (ex : mysql)
  <NOM_SERVICE_DB>:
    # ex : mysql:8.0 ou mariadb:11
    image: <IMAGE_DB>:<TAG>
    restart: always
    environment:
      # mot de passe root de la base
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      # base créée au premier démarrage
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      # compte créé pour l'application
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      # dossier des données MySQL, sauvegardé dans le volume
      - <NOM_VOLUME_DB>:/var/lib/mysql
    networks:
      - <NOM_RESEAU>
    # pas de "ports:" : jamais joignable depuis Internet, seulement sur le réseau docker (3306)
```

## compose.app.yml.j2 (application PHP-FPM + outil wp-cli)

```yaml
services:
  <NOM_SERVICE_APP>:
    # ex : wordpress:php8.1-fpm (PHP sans serveur web, nginx s'en charge)
    image: <IMAGE_APP>:<TAG>
    restart: always
    # démarre la base avant l'application
    depends_on:
      - <NOM_SERVICE_DB>
    environment:
      # adresse de la base = nom de son service
      WORDPRESS_DB_HOST: <NOM_SERVICE_DB>
      # identifiants de la base, repris du .env
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      # fichiers du site, dans un volume pour survivre au reboot
      - <NOM_VOLUME_APP>:/var/www/html
    networks:
      - <NOM_RESEAU>

  <NOM_SERVICE_OUTIL>:
    # ex : wordpress:cli
    image: <IMAGE_OUTIL>:<TAG>
    # ne démarre PAS avec "docker compose up", seulement avec "--profile tools run"
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
      # même volume que l'appli : l'outil voit et modifie les mêmes fichiers
      - <NOM_VOLUME_APP>:/var/www/html
    networks:
      - <NOM_RESEAU>
    # tourne en www-data (33), comme php-fpm, pour ne pas casser les droits
    user: "33:33"
```

## compose.admin.yml.j2 (ex : phpMyAdmin derrière nginx)

```yaml
services:
  <NOM_SERVICE_ADMIN>:
    # ex : phpmyadmin:latest
    image: <IMAGE_ADMIN>:<TAG>
    restart: always
    depends_on:
      - <NOM_SERVICE_DB>
    environment:
      # adresse et port de la base
      PMA_HOST: <NOM_SERVICE_DB>
      PMA_PORT: "3306"
      # URL publique complète pour que les liens marchent sous /<CHEMIN_URL>/
      # ajoute ":port" seulement si HTTPS n'est pas sur 443
      PMA_ABSOLUTE_URI: https://{{ ansible_host }}{% if https_port | int != 443 %}:{{ https_port }}{% endif %}/<CHEMIN_URL>/
    networks:
      - <NOM_RESEAU>
    # pas de "ports:" : accessible uniquement via nginx
```

## compose.proxy.yml.j2 (nginx, le seul exposé)

```yaml
services:
  nginx:
    # image nginx légère
    image: nginx:alpine
    restart: always
    depends_on:
      - <NOM_SERVICE_APP>
      - <NOM_SERVICE_ADMIN>
    # le SEUL service qui publie des ports sur le serveur
    ports:
      - "{{ http_port }}:80"
      - "{{ https_port }}:443"
    volumes:
      # config nginx générée par Ansible, à la place de la config par défaut (:ro = lecture seule)
      - {{ project_dir }}/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      # certificats TLS
      - {{ project_dir }}/ssl:/etc/nginx/ssl:ro
      # fichiers du site : nginx sert images et CSS sans passer par PHP
      - <NOM_VOLUME_APP>:/var/www/html
    networks:
      - <NOM_RESEAU>
```

## Syntaxe Jinja dans les .j2

- `{% if condition %} ... {% endif %}` : condition
- `{% for x in liste %} ... {% endfor %}` : boucle
- `{{ liste | join(':') }}` : colle les éléments avec `:`
- `{{ variable | default('x') }}` : valeur par défaut
- `{# texte #}` : commentaire Jinja, absent du fichier final
