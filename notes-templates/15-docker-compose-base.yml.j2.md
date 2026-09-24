# roles/stack/templates/docker-compose.yml.j2 (compose socle)

## À quoi ça sert

Déclare seulement le réseau et les volumes partagés. Chaque service arrive ensuite dans son propre fichier `compose.<NOM_SERVICE>.yml`. Docker les fusionne grâce à `COMPOSE_FILE` dans le `.env`.

## Le fichier

```yaml
networks:
  <NOM_RESEAU>:
    driver: bridge

volumes:
  <NOM_VOLUME_DB>:
  <NOM_VOLUME_APP>:
```

## Ligne par ligne

- `networks:` : liste des réseaux docker
- `<NOM_RESEAU>:` : nom du réseau privé où les conteneurs se parlent
- `driver: bridge` : réseau local à la machine, isolé de l'extérieur
- `volumes:` : liste des volumes nommés
- `<NOM_VOLUME_DB>:` : stockage de la base de données, survit à l'arrêt et au reboot
- `<NOM_VOLUME_APP>:` : stockage des fichiers de l'application

## Variante tout-en-un (un seul fichier compose)

```yaml
services:
  <NOM_SERVICE>:
    image: <IMAGE>:<TAG>
    restart: always
    env_file: .env
    ports:
      - "<PORT_HOTE>:<PORT_CONTENEUR>"
    volumes:
      - <NOM_VOLUME>:<CHEMIN_DANS_CONTENEUR>
    networks:
      - <NOM_RESEAU>

networks:
  <NOM_RESEAU>:
    driver: bridge

volumes:
  <NOM_VOLUME>:
```

- `services:` : liste des conteneurs
- `image:` : image docker à utiliser
- `restart: always` : redémarre le conteneur s'il plante et au reboot
- `env_file: .env` : charge toutes les variables du `.env` dans le conteneur
- `ports:` : `port du serveur:port du conteneur`, rend le service joignable de l'extérieur
- `volumes:` : `volume:chemin dans le conteneur`, les données y sont conservées
- `networks:` : réseau(x) auquel le conteneur est branché

## À retenir

- Un volume nommé n'est supprimé que par `docker compose down -v`
- Son vrai nom sur le serveur : `<nom_du_dossier>_<NOM_VOLUME>` (ex : `wordpress_mysql_data`)
- Sur un même réseau, les conteneurs se joignent par leur nom de service (ex : `mysql:3306`)
