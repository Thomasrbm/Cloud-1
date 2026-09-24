# group_vars/all.yml

## À quoi ça sert

Variables en clair, appliquées automatiquement à tous les serveurs. Tu les utilises partout avec `{{ nom_variable }}`. Pas de secrets ici.

## Le fichier

```yaml
---
project_dir: <PROJECT_DIR>
domain_name: <DOMAINE>

http_port: 80
https_port: 443

allow_root_ssh: true

swap_enabled: true
swap_file: /swapfile
swap_size_mb: <TAILLE_SWAP_MO>
swap_swappiness: 10

compose_files:
  - docker-compose.yml
  - compose.<SERVICE_DB>.yml
  - compose.<SERVICE_APP>.yml
  - compose.<SERVICE_ADMIN>.yml
  - compose.proxy.yml

app_site_url: "https://{{ ansible_host }}{% if https_port | int != 443 %}:{{ https_port }}{% endif %}"
app_site_title: "<TITRE_SITE>"
app_admin_user: <ADMIN_USER>
app_admin_email: <ADMIN_EMAIL>
```

## Ligne par ligne

- `project_dir` : dossier sur le serveur où vivent le `.env`, les compose, la config nginx et les certificats
- `domain_name` : nom mis dans le certificat TLS
- `http_port` / `https_port` : ports publiés par nginx sur le serveur
- `allow_root_ssh` : si `true`, le rôle ssh_access autorise `ssh root@<IP_SERVEUR>` par clé
- `swap_enabled` : active ou non le rôle swap
- `swap_file` : chemin du fichier d'échange
- `swap_size_mb` : taille du swap en Mo (ex : 2048)
- `swap_swappiness` : 10 = le système n'utilise le swap qu'en dernier recours
- `compose_files` : liste des fichiers compose, fusionnés par Docker dans cet ordre. Elle est écrite dans le `.env`
- `app_site_url` : URL du site. Ajoute `:port` seulement si le port HTTPS n'est pas 443
- `app_site_title` : titre du site
- `app_admin_user` : identifiant du compte admin de l'application
- `app_admin_email` : email du compte admin

## Ordre de priorité des variables

La dernière de la liste gagne :

1. `roles/<NOM_ROLE>/defaults/main.yml`
2. `group_vars/all.yml`
3. `group_vars/<NOM_GROUPE>.yml`
4. `host_vars/<NOM_HOTE>.yml`
5. `vars:` dans le playbook
6. `-e <VAR>=<VALEUR>` en ligne de commande
