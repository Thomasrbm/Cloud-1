# roles/stack/templates/docker-compose.yml.j2 (socle)

Juste le réseau et les volumes nommés. Chaque service arrive dans son propre `compose.<service>.yml`, fusionnés via `COMPOSE_FILE` dans le `.env`.

```yaml
networks:
  <NOM_RESEAU>:
    driver: bridge

volumes:
  <NOM_VOLUME_DB>:
  <NOM_VOLUME_APP>:
```

## Variante tout-en-un (un seul fichier)

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

## Rappels

- Volume nommé → survit au `down` et au reboot (supprimé seulement par `down -v`).
- Le nom réel sur l'hôte = `<nom_du_dossier>_<NOM_VOLUME>` (ex: `wordpress_mysql_data`).
- Services sur le même réseau → se joignent par leur **nom de service** (DNS docker).
