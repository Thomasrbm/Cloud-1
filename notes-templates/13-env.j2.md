# roles/stack/templates/env.j2 → `<PROJECT_DIR>/.env` (mode 0600)

```bash
# Généré par Ansible depuis group_vars/<NOM_GROUPE>.yml (vault)

# Liste des fichiers compose fusionnés : un simple "docker compose ps"
# dans {{ project_dir }} voit tous les services.
COMPOSE_FILE={{ compose_files | join(':') }}

MYSQL_ROOT_PASSWORD={{ <DB>_root_password }}
MYSQL_DATABASE={{ <DB>_database }}
MYSQL_USER={{ <DB>_user }}
MYSQL_PASSWORD={{ <DB>_password }}

# <AUTRE_VARIABLE>={{ <autre_variable_ansible> }}
```

## Rendu final sur le serveur (exemple)

```bash
COMPOSE_FILE=docker-compose.yml:compose.db.yml:compose.app.yml:compose.proxy.yml
MYSQL_ROOT_PASSWORD=<MDP_ROOT_DB>
MYSQL_DATABASE=<NOM_BASE>
MYSQL_USER=<USER_DB>
MYSQL_PASSWORD=<MDP_USER_DB>
```

- `mode: '0600'` dans la tâche template → lisible uniquement par root.
- `notify: Recreate stack` → un conteneur ne relit le `.env` qu'à sa (re)création.
