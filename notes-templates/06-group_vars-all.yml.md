# group_vars/all.yml

- Variables en clair, appliquées automatiquement à tous les serveurs
- Utilisées partout avec `{{ nom_variable }}`
- Pas de secrets ici

```yaml
---
# dossier sur le serveur : .env, compose, config nginx, certificats
project_dir: <PROJECT_DIR>

# nom mis dans le certificat TLS
domain_name: <DOMAINE>

# ports publiés par nginx sur le serveur
http_port: 80
https_port: 443

# true = le rôle ssh_access autorise "ssh root@<IP_SERVEUR>" par clé (jamais par mot de passe)
allow_root_ssh: true

# --- swap ---
# active ou non le rôle swap
swap_enabled: true
# chemin du fichier d'échange
swap_file: /swapfile
# taille en Mo (ex : 2048)
swap_size_mb: <TAILLE_SWAP_MO>
# 10 = le système n'utilise le swap qu'en dernier recours (60 par défaut)
swap_swappiness: 10

# --- fichiers compose ---
# fusionnés par Docker dans cet ordre, la liste est écrite dans le .env (COMPOSE_FILE)
compose_files:
  # socle : réseau + volumes
  - docker-compose.yml
  - compose.<SERVICE_DB>.yml
  - compose.<SERVICE_APP>.yml
  - compose.<SERVICE_ADMIN>.yml
  - compose.proxy.yml

# --- application ---
# URL du site, ajoute ":port" seulement si le port HTTPS n'est pas 443
app_site_url: "https://{{ ansible_host }}{% if https_port | int != 443 %}:{{ https_port }}{% endif %}"
# titre du site
app_site_title: "<TITRE_SITE>"
# compte admin de l'application (son mot de passe est dans le vault)
app_admin_user: <ADMIN_USER>
app_admin_email: <ADMIN_EMAIL>
```

## Priorité des variables (la dernière gagne)

1. `roles/<NOM_ROLE>/defaults/main.yml`
2. `group_vars/all.yml`
3. `group_vars/<NOM_GROUPE>.yml`
4. `host_vars/<NOM_HOTE>.yml`
5. `vars:` dans le playbook
6. `-e <VAR>=<VALEUR>` en ligne de commande
