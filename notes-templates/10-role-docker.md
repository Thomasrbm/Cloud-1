# roles/docker/tasks/main.yml

- Installe Docker Engine + `docker compose` depuis le dépôt officiel, démarré au boot

```yaml
---
# outils nécessaires pour ajouter un dépôt externe
#   apt-transport-https : télécharger des paquets en HTTPS
#   ca-certificates     : vérifier les certificats des sites
#   curl                : télécharger des fichiers
#   gnupg               : gérer les clés de signature
#   lsb-release         : connaître la version d'Ubuntu
- name: Install prerequisite packages
  apt:
    name: [apt-transport-https, ca-certificates, curl, gnupg, lsb-release]
    state: present
    update_cache: true

# dossier où Ubuntu range les clés des dépôts
- name: Create keyrings directory
  file:
    path: /etc/apt/keyrings
    state: directory
    mode: '0755'

# clé officielle Docker : prouve que les paquets viennent bien de Docker
# .asc = clé au format texte
- name: Add Docker GPG key
  get_url:
    url: https://download.docker.com/linux/ubuntu/gpg
    dest: /etc/apt/keyrings/docker.asc
    mode: '0644'

# ajoute le dépôt Docker aux sources d'apt
#   arch=...                         : amd64 ou arm64 selon le processeur du serveur
#   signed-by=                       : n'accepte que les paquets signés par la clé ci-dessus
#   ansible_distribution_release     : version d'Ubuntu (ex : jammy), détectée par Ansible
#   filename: docker                 : crée /etc/apt/sources.list.d/docker.list
- name: Add Docker apt repository
  apt_repository:
    repo: >-
      deb [arch={{ 'amd64' if ansible_architecture == 'x86_64' else 'arm64' }}
      signed-by=/etc/apt/keyrings/docker.asc]
      https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable
    filename: docker
    state: present

# docker-ce             : le moteur
# docker-ce-cli         : la commande docker
# containerd.io         : gestionnaire bas niveau des conteneurs
# docker-buildx-plugin  : construction d'images
# docker-compose-plugin : la commande docker compose
- name: Install Docker Engine and Compose plugin
  apt:
    name: [docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin]
    state: present
    update_cache: true

# démarre Docker maintenant (started) et à chaque boot (enabled)
- name: Ensure Docker is enabled and running
  service:
    name: docker
    state: started
    enabled: true
```
