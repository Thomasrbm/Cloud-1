# roles/stack (le socle)

## À quoi ça sert

Prépare ce dont tous les autres rôles ont besoin : le dossier du projet, le `.env` avec les secrets, et le compose de base (réseau + volumes). Aucun conteneur applicatif ici.

## tasks/main.yml

```yaml
---
- name: Create project directory
  file:
    path: "{{ project_dir }}"
    state: directory
    mode: '0755'

- name: Deploy .env file
  template:
    src: env.j2
    dest: "{{ project_dir }}/.env"
    mode: '0600'
  notify: Recreate stack

- name: Deploy base compose file
  template:
    src: docker-compose.yml.j2
    dest: "{{ project_dir }}/docker-compose.yml"
    mode: '0644'
  notify: Recreate stack
```

## Tâche par tâche

- **Create project directory** : crée `<PROJECT_DIR>` sur le serveur
- **Deploy .env file** :
  - génère `.env` à partir de `templates/env.j2` et des secrets du vault
  - `mode: '0600'` : lisible uniquement par root
  - doit exister avant le premier `docker compose`
  - `notify: Recreate stack` : si les secrets changent, les conteneurs sont recréés
- **Deploy base compose file** : dépose le compose qui déclare le réseau et les volumes

## handlers/main.yml

```yaml
---
- name: Recreate stack
  command: docker compose up -d --force-recreate --remove-orphans
  args:
    chdir: "{{ project_dir }}"
```

- `--force-recreate` : recrée tous les conteneurs pour qu'ils relisent le nouveau `.env`
- `--remove-orphans` : supprime les anciens conteneurs qui ne sont plus déclarés
