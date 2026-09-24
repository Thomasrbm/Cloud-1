# Templates Ansible génériques (Cloud-1)

Une note par type de fichier. Chaque note contient :

- **À quoi sert le fichier**
- **Le fichier complet**, sans commentaires, prêt à copier
- **L'explication ligne par ligne**, en dehors des blocs de code

## Placeholders à remplacer

- `<IP_SERVEUR>` : IP publique du serveur (ex : 13.60.10.20)
- `<SSH_USER>` : utilisateur SSH (ex : ubuntu sur AWS, ou root)
- `<CHEMIN_CLE_PRIVEE>` : chemin de la clé privée (ex : ~/.ssh/ma-cle.pem)
- `<NOM_GROUPE>` : nom du groupe de serveurs (ex : webservers)
- `<NOM_HOTE>` : surnom d'un serveur (ex : server1)
- `<PROJECT_DIR>` : dossier du projet sur le serveur (ex : /opt/wordpress)
- `<DOMAINE>` : nom de domaine (ex : localhost)
- `<NOM_ROLE>` : nom d'un rôle (ex : db, proxy)
- `<NOM_SERVICE>` : nom d'un service docker compose (ex : mysql, nginx)
- `<NOM_RESEAU>` : réseau docker (ex : wp_network)
- `<NOM_VOLUME>` : volume docker nommé (ex : mysql_data)
- `<IMAGE>:<TAG>` : image docker (ex : mysql:8.0)
- `<MDP_...>` : mot de passe, à mettre dans le vault

## Sommaire

- `01-arborescence.md` : structure d'un projet Ansible
- `02-ansible.cfg.md` : configuration d'Ansible
- `03-inventory.ini.md` : liste des serveurs
- `04-playbook.yml.md` : playbook principal
- `05-requirements.yml.md` : collections à installer
- `06-group_vars-all.yml.md` : variables en clair
- `07-group_vars-vault.md` : secrets chiffrés
- `08-role-tasks.md` : les briques de tâches
- `09-role-handlers.md` : les handlers
- `10-role-docker.md` : rôle d'installation de Docker
- `11-role-ufw.md` : rôle pare-feu
- `12-role-swap.md` : rôle swap
- `13-role-ssh-access.md` : rôle accès SSH
- `14-role-stack.md` : rôle socle (dossier, .env, compose de base)
- `15-docker-compose-base.yml.j2.md` : compose socle
- `16-compose-services.yml.j2.md` : compose par service
- `17-env.j2.md` : fichier .env
- `18-nginx.conf.j2.md` : nginx reverse proxy
- `19-teardown.yml.md` : désinstallation
- `20-gitignore-et-cles-ssh.md` : .gitignore et clés
- `21-commandes.md` : aide-mémoire des commandes
