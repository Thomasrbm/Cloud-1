# roles/stack/templates/env.j2

## À quoi ça sert

Génère `<PROJECT_DIR>/.env` sur le serveur. Docker compose le lit automatiquement : il y trouve la liste des fichiers compose et les mots de passe.

## Le fichier

```bash
COMPOSE_FILE={{ compose_files | join(':') }}
MYSQL_ROOT_PASSWORD={{ <DB>_root_password }}
MYSQL_DATABASE={{ <DB>_database }}
MYSQL_USER={{ <DB>_user }}
MYSQL_PASSWORD={{ <DB>_password }}
```

## Ligne par ligne

- `COMPOSE_FILE=` : liste des fichiers compose à fusionner, séparés par `:`. Grâce à elle, un simple `docker compose ps` voit tous les services
- `{{ compose_files | join(':') }}` : prend la liste de `group_vars/all.yml` et la colle avec `:`
- `MYSQL_ROOT_PASSWORD=` : mot de passe root, vient du vault
- `MYSQL_DATABASE=` : nom de la base, vient du vault
- `MYSQL_USER=` : utilisateur de la base, vient du vault
- `MYSQL_PASSWORD=` : mot de passe de cet utilisateur, vient du vault

## Résultat sur le serveur

```bash
COMPOSE_FILE=docker-compose.yml:compose.db.yml:compose.app.yml:compose.proxy.yml
MYSQL_ROOT_PASSWORD=<MDP_ROOT_DB>
MYSQL_DATABASE=<NOM_BASE>
MYSQL_USER=<USER_DB>
MYSQL_PASSWORD=<MDP_USER_DB>
```

## À retenir

- Déposé avec `mode: '0600'` : seul root peut le lire
- Avec `notify: Recreate stack` : un conteneur ne relit le `.env` qu'à sa création
- Ne jamais commit un `.env` réel
