# roles/stack/templates/env.j2

- Génère `<PROJECT_DIR>/.env` sur le serveur
- Docker compose le lit automatiquement : liste des fichiers compose + mots de passe
- Déposé en `0600` (root seulement), jamais commité

```bash
# Généré par Ansible depuis group_vars/<NOM_GROUPE>.yml (vault)

# fichiers compose à fusionner, séparés par ":"
# grâce à ça, un simple "docker compose ps" voit tous les services
COMPOSE_FILE={{ compose_files | join(':') }}

# mot de passe root de la base (vault)
MYSQL_ROOT_PASSWORD={{ <DB>_root_password }}

# nom de la base (vault)
MYSQL_DATABASE={{ <DB>_database }}

# utilisateur de la base et son mot de passe (vault)
MYSQL_USER={{ <DB>_user }}
MYSQL_PASSWORD={{ <DB>_password }}
```

## Résultat sur le serveur

```bash
COMPOSE_FILE=docker-compose.yml:compose.db.yml:compose.app.yml:compose.proxy.yml
MYSQL_ROOT_PASSWORD=<MDP_ROOT_DB>
MYSQL_DATABASE=<NOM_BASE>
MYSQL_USER=<USER_DB>
MYSQL_PASSWORD=<MDP_USER_DB>
```
