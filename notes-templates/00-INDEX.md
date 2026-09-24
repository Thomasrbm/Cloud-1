# Templates Ansible génériques (Cloud-1)

- Une note = un type de fichier
- Chaque note = un seul bloc de code complet, commenté ligne par ligne, prêt à copier
- Remplace les `<PLACEHOLDERS>` par tes valeurs

## Placeholders

- `<IP_SERVEUR>` : IP publique du serveur
- `<SSH_USER>` : utilisateur SSH (ubuntu sur AWS)
- `<CHEMIN_CLE_PRIVEE>` : clé privée (ex : ~/.ssh/ma-cle.pem)
- `<NOM_GROUPE>` : groupe de serveurs (ex : webservers)
- `<NOM_HOTE>` : surnom d'un serveur (ex : server1)
- `<PROJECT_DIR>` : dossier du projet sur le serveur (ex : /opt/wordpress)
- `<DOMAINE>` : nom de domaine (ex : localhost)
- `<NOM_ROLE>` / `<NOM_SERVICE>` : rôle Ansible / service docker
- `<NOM_RESEAU>` / `<NOM_VOLUME>` : réseau / volume docker
- `<IMAGE>:<TAG>` : image docker (ex : mysql:8.0)
- `<MDP_...>` : mot de passe (dans le vault)

## Sommaire

- `01-arborescence.md`
- `02-ansible.cfg.md`
- `03-inventory.ini.md`
- `04-playbook.yml.md`
- `05-requirements.yml.md`
- `06-group_vars-all.yml.md`
- `07-group_vars-vault.md`
- `08-role-tasks.md` (toutes les briques de tâches)
- `09-role-handlers.md`
- `10-role-docker.md`
- `11-role-ufw.md`
- `12-role-swap.md`
- `13-role-ssh-access.md`
- `14-role-stack.md`
- `15-docker-compose-base.yml.j2.md`
- `16-compose-services.yml.j2.md`
- `17-env.j2.md`
- `18-nginx.conf.j2.md`
- `19-teardown.yml.md`
- `20-gitignore-et-cles-ssh.md`
- `21-commandes.md`
