# roles/docker/tasks/main.yml

## À quoi ça sert

Installe Docker Engine et le plugin `docker compose` depuis le dépôt officiel de Docker, puis le démarre au boot.

## Le fichier

```yaml
---
- name: Install prerequisite packages
  apt:
    name: [apt-transport-https, ca-certificates, curl, gnupg, lsb-release]
    state: present
    update_cache: true

- name: Create keyrings directory
  file:
    path: /etc/apt/keyrings
    state: directory
    mode: '0755'

- name: Add Docker GPG key
  get_url:
    url: https://download.docker.com/linux/ubuntu/gpg
    dest: /etc/apt/keyrings/docker.asc
    mode: '0644'

- name: Add Docker apt repository
  apt_repository:
    repo: >-
      deb [arch={{ 'amd64' if ansible_architecture == 'x86_64' else 'arm64' }}
      signed-by=/etc/apt/keyrings/docker.asc]
      https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable
    filename: docker
    state: present

- name: Install Docker Engine and Compose plugin
  apt:
    name: [docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin]
    state: present
    update_cache: true

- name: Ensure Docker is enabled and running
  service:
    name: docker
    state: started
    enabled: true
```

## Tâche par tâche

- **Install prerequisite packages** : outils nécessaires pour ajouter un dépôt externe
  - `apt-transport-https` : télécharger des paquets en HTTPS
  - `ca-certificates` : vérifier les certificats des sites
  - `curl` : télécharger des fichiers
  - `gnupg` : gérer les clés de signature
  - `lsb-release` : connaître la version d'Ubuntu
- **Create keyrings directory** : dossier où Ubuntu range les clés des dépôts
- **Add Docker GPG key** : télécharge la clé officielle de Docker, qui prouve que les paquets viennent bien de Docker
  - `get_url:` : module de téléchargement
  - `.asc` : clé au format texte
- **Add Docker apt repository** : ajoute le dépôt Docker aux sources d'apt
  - `arch=...` : choisit `amd64` ou `arm64` selon le processeur du serveur
  - `signed-by=` : n'accepte que les paquets signés par la clé téléchargée juste avant
  - `{{ ansible_distribution_release }}` : nom de la version d'Ubuntu (ex : jammy), détecté par Ansible
  - `filename: docker` : crée `/etc/apt/sources.list.d/docker.list`
- **Install Docker Engine and Compose plugin** :
  - `docker-ce` : le moteur Docker
  - `docker-ce-cli` : la commande `docker`
  - `containerd.io` : le gestionnaire bas niveau des conteneurs
  - `docker-buildx-plugin` : construction d'images
  - `docker-compose-plugin` : la commande `docker compose`
- **Ensure Docker is enabled and running** : démarre Docker maintenant et à chaque boot
