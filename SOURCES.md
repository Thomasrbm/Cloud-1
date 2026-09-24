# Sources de la documentation

Pour reproduire chaque `main.yml` de rôle, voici la doc officielle correspondante.
Le principe est toujours le même : la doc de l'outil donne les commandes shell,
on les traduit avec les [modules Ansible](https://docs.ansible.com/ansible/latest/collections/index_module.html).

## Rôles

- **docker** → installer Docker Engine sur Ubuntu : https://docs.docker.com/engine/install/ubuntu/
- **db** (MySQL) → image officielle MySQL : https://hub.docker.com/_/mysql
- **wordpress** → image officielle WordPress + WP-CLI : https://hub.docker.com/_/wordpress et https://developer.wordpress.org/cli/commands/
- **phpmyadmin** → image officielle phpMyAdmin : https://hub.docker.com/_/phpmyadmin
- **proxy** (nginx + SSL) → image officielle nginx : https://hub.docker.com/_/nginx et certificat auto-signé OpenSSL : https://www.openssl.org/docs/manmaster/man1/openssl-req.html
- **stack** (compose de base) → référence Docker Compose : https://docs.docker.com/compose/compose-file/
- **swap** → gestion du swap Linux (fallocate / mkswap / swapon) : https://help.ubuntu.com/community/SwapFaq
- **ufw** → pare-feu UFW : https://help.ubuntu.com/community/UFW
- **ssh_access** → config du serveur SSH (sshd_config) : https://manpages.ubuntu.com/manpages/noble/en/man5/sshd_config.5.html

## Modules Ansible utilisés

- `ansible.builtin.apt`, `get_url`, `apt_repository`, `file`, `service`, `template`, `command`, `lineinfile`, `sysctl` : https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html
- `community.general.ufw` : https://docs.ansible.com/ansible/latest/collections/community/general/ufw_module.html
- Gérer conteneurs/images en Ansible (non utilisé ici, mais utile) : https://docs.ansible.com/ansible/latest/collections/community/docker/
