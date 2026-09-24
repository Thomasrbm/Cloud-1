# Templates Ansible génériques (tirés de Cloud-1)

Un fichier `.md` = un type de fichier du projet, prêt à copier-coller.
Remplace tous les `<PLACEHOLDERS>` par tes valeurs.

## Placeholders utilisés partout

| Placeholder | Exemple | Sens |
|---|---|---|
| `<IP_SERVEUR>` | `13.60.x.x` | IP publique du serveur cible |
| `<SSH_USER>` | `ubuntu` / `root` | Utilisateur SSH |
| `<CHEMIN_CLE_PRIVEE>` | `~/.ssh/ma-cle.pem` | Clé privée SSH (chmod 400) |
| `<NOM_GROUPE>` | `webservers` | Groupe d'hôtes de l'inventaire |
| `<NOM_HOTE>` | `server1` | Alias d'un hôte |
| `<PROJECT_DIR>` | `/opt/monapp` | Dossier du projet sur le serveur |
| `<DOMAINE>` | `monsite.fr` / `localhost` | Nom de domaine |
| `<NOM_ROLE>` | `db`, `proxy`... | Nom d'un rôle |
| `<NOM_SERVICE>` | `mysql`, `nginx`... | Service docker compose |
| `<NOM_RESEAU>` | `app_network` | Réseau docker |
| `<NOM_VOLUME>` | `db_data` | Volume docker nommé |
| `<IMAGE>:<TAG>` | `mysql:8.0` | Image docker |
| `<MDP_...>` | — | Secrets (à mettre dans le vault) |

## Sommaire

| Fichier | Contenu |
|---|---|
| `01-arborescence.md` | Structure d'un projet Ansible + rôles |
| `02-ansible.cfg.md` | Config Ansible |
| `03-inventory.ini.md` | Inventaire des serveurs |
| `04-playbook.yml.md` | Playbook principal (liste des rôles + tags) |
| `05-requirements.yml.md` | Collections Galaxy |
| `06-group_vars-all.yml.md` | Variables en clair |
| `07-group_vars-vault.md` | Secrets chiffrés (ansible-vault) |
| `08-role-tasks.md` | `roles/*/tasks/main.yml` : tous les patterns de tâches |
| `09-role-handlers.md` | `roles/*/handlers/main.yml` |
| `10-role-exemples-systeme.md` | Rôles système complets : docker, ufw, swap, ssh |
| `11-docker-compose-base.yml.j2.md` | Compose socle (réseau + volumes) |
| `12-compose-service.yml.j2.md` | Compose par service (db, app php, admin, proxy) |
| `13-env.j2.md` | Template `.env` |
| `14-nginx.conf.j2.md` | Reverse proxy nginx + TLS + php-fpm |
| `15-teardown.yml.md` | Playbook de désinstallation |
| `16-gitignore-et-cles-ssh.md` | `.gitignore` + fichiers `.pub` |
| `17-commandes.md` | Toutes les commandes utiles (anti-sèche) |
