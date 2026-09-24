# roles/stack/templates/docker-compose.yml.j2 (compose socle)

- Déclare seulement le réseau et les volumes partagés
- Chaque service arrive dans son propre `compose.<NOM_SERVICE>.yml`
- Docker les fusionne grâce à `COMPOSE_FILE` dans le `.env`

```yaml
# liste des réseaux docker
networks:
  # réseau privé où les conteneurs se parlent (par leur nom de service)
  <NOM_RESEAU>:
    # réseau local à la machine, isolé de l'extérieur
    driver: bridge

# liste des volumes nommés (survivent à l'arrêt et au reboot)
volumes:
  # données de la base
  <NOM_VOLUME_DB>:
  # fichiers de l'application
  <NOM_VOLUME_APP>:
```

## Variante tout-en-un (un seul fichier compose)

```yaml
# liste des conteneurs
services:
  <NOM_SERVICE>:
    # image docker à utiliser
    image: <IMAGE>:<TAG>
    # redémarre si le conteneur plante et au reboot
    restart: always
    # charge toutes les variables du .env dans le conteneur
    env_file: .env
    # "port du serveur:port du conteneur" -> joignable de l'extérieur
    ports:
      - "<PORT_HOTE>:<PORT_CONTENEUR>"
    # "volume:chemin dans le conteneur" -> données conservées
    volumes:
      - <NOM_VOLUME>:<CHEMIN_DANS_CONTENEUR>
    # réseau(x) auquel le conteneur est branché
    networks:
      - <NOM_RESEAU>

networks:
  <NOM_RESEAU>:
    driver: bridge

volumes:
  <NOM_VOLUME>:
```

- Un volume nommé n'est supprimé que par `docker compose down -v`
- Son vrai nom sur le serveur : `<nom_du_dossier>_<NOM_VOLUME>` (ex : `wordpress_mysql_data`)
