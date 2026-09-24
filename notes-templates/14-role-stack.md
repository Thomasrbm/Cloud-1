# roles/stack (le socle)

- Prépare ce dont tous les autres rôles ont besoin : dossier, `.env`, réseau, volumes
- Aucun conteneur applicatif ici

## tasks/main.yml

```yaml
---
# crée <PROJECT_DIR> sur le serveur
- name: Create project directory
  file:
    path: "{{ project_dir }}"
    state: directory
    mode: '0755'

# génère le .env depuis templates/env.j2 + les secrets du vault
# doit exister AVANT le premier docker compose
# 0600 = lisible uniquement par root
# notify : si les secrets changent, les conteneurs sont recréés
- name: Deploy .env file
  template:
    src: env.j2
    dest: "{{ project_dir }}/.env"
    mode: '0600'
  notify: Recreate stack

# dépose le compose qui déclare le réseau et les volumes
- name: Deploy base compose file
  template:
    src: docker-compose.yml.j2
    dest: "{{ project_dir }}/docker-compose.yml"
    mode: '0644'
  notify: Recreate stack
```

## handlers/main.yml

```yaml
---
# --force-recreate : recrée tous les conteneurs pour qu'ils relisent le nouveau .env
# --remove-orphans : supprime les anciens conteneurs qui ne sont plus déclarés
- name: Recreate stack
  command: docker compose up -d --force-recreate --remove-orphans
  args:
    chdir: "{{ project_dir }}"
```
