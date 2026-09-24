# group_vars/all.yml (variables en clair)

```yaml
---
# S'applique automatiquement à TOUS les hôtes.

project_dir: <PROJECT_DIR>          # ex: /opt/wordpress
domain_name: <DOMAINE>              # ex: localhost

http_port: 80
https_port: 443

# Accès root par clé SSH (jamais par mot de passe)
allow_root_ssh: true

# --- Swap (petites VM sans swap, ex: t3.micro 1 Go) ---
swap_enabled: true
swap_file: /swapfile
swap_size_mb: <TAILLE_SWAP_MO>      # ex: 2048
swap_swappiness: 10

# --- Fichiers compose fusionnés (écrits dans le .env via COMPOSE_FILE) ---
compose_files:
  - docker-compose.yml              # socle : réseau + volumes
  - compose.<SERVICE_DB>.yml
  - compose.<SERVICE_APP>.yml
  - compose.<SERVICE_ADMIN>.yml
  - compose.proxy.yml

# --- Application ---
app_site_url: "https://{{ ansible_host }}{% if https_port | int != 443 %}:{{ https_port }}{% endif %}"
app_site_title: "<TITRE_SITE>"
app_admin_user: <ADMIN_USER>
app_admin_email: <ADMIN_EMAIL>
# Les mots de passe vont dans group_vars/<NOM_GROUPE>.yml (vault)
```

## Priorité des variables (de la + faible à la + forte, simplifié)

1. `roles/*/defaults/main.yml`
2. `group_vars/all.yml`
3. `group_vars/<NOM_GROUPE>.yml`
4. `host_vars/<NOM_HOTE>.yml`
5. `vars:` du playbook
6. `-e <var>=<valeur>` en ligne de commande (gagne toujours)
