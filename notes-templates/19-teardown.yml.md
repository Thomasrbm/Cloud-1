# teardown.yml

- Remet le serveur à zéro pour rejouer le déploiement
- Standard : conteneurs, images, données supprimés, Docker reste
- Total (`-e full_wipe=true`) : désinstalle aussi Docker, swap, remet ufw à zéro

```yaml
---
# ansible-playbook teardown.yml --ask-vault-pass                    -> standard
# ansible-playbook teardown.yml --ask-vault-pass -e full_wipe=true  -> total
# --ask-vault-pass reste nécessaire : Ansible charge le vault du groupe

- name: Teardown <NOM_PROJET>
  hosts: <NOM_GROUPE>
  become: true

  # niveau standard par défaut
  vars:
    full_wipe: false

  # pose une question avant de commencer (private: false = la réponse s'affiche)
  vars_prompt:
    - name: confirm
      prompt: "Effacer la stack et TOUTES les données sur {{ ansible_play_hosts | join(', ') }} ? (tape: oui)"
      private: false

  tasks:

    # ------------------------------------------------------------------
    # Garde-fous
    # ------------------------------------------------------------------
    # arrête tout si la réponse n'est pas oui
    - name: Abort unless confirmed
      assert:
        that: [ "confirm | lower in ['oui', 'yes', 'y']" ]
        fail_msg: "Annulé : rien n'a été supprimé."
        quiet: true

    # empêche de supprimer / ou un dossier système si project_dir est mal réglé
    - name: Refuse to delete a dangerous path
      assert:
        that:
          - project_dir is defined
          - project_dir | length > 4
          - project_dir.startswith('/')
          - project_dir not in ['/', '/root', '/home', '/etc', '/var', '/usr', '/opt']
        fail_msg: "project_dir suspect : abandon."
        quiet: true

    # docker_present.rc == 0 si Docker est installé
    - name: Check whether docker is installed
      command: docker --version
      register: docker_present
      changed_when: false
      failed_when: false

    # ------------------------------------------------------------------
    # Suppression de la stack
    # ------------------------------------------------------------------
    # vérifie que le projet existe encore
    - name: Check for compose file
      stat:
        path: "{{ project_dir }}/docker-compose.yml"
      register: compose_file

    # down = arrête et supprime conteneurs + réseau
    # -v = supprime aussi les volumes (données) / --rmi all = et les images
    - name: Stop and remove containers, volumes, images
      command: docker compose down -v --remove-orphans --rmi all
      args:
        chdir: "{{ project_dir }}"
      when: [ compose_file.stat.exists, docker_present.rc == 0 ]
      failed_when: false

    # filet de sécurité si le .env avait disparu
    # project_dir | basename = dernier morceau du chemin (préfixe des volumes)
    - name: Remove named volumes explicitly
      command: "docker volume rm {{ item }}"
      loop:
        - "{{ project_dir | basename }}_<NOM_VOLUME_DB>"
        - "{{ project_dir | basename }}_<NOM_VOLUME_APP>"
      when: docker_present.rc == 0
      failed_when: false

    # supprime config, certificats et fichiers compose
    - name: Remove project directory
      file:
        path: "{{ project_dir }}"
        state: absent

    # nettoie tout ce que Docker garde encore (cache, images, réseaux)
    - name: Prune docker
      command: docker system prune -af --volumes
      when: docker_present.rc == 0
      failed_when: false

    # ------------------------------------------------------------------
    # Désinstallation totale (seulement avec -e full_wipe=true)
    # ------------------------------------------------------------------
    - name: Full wipe
      when: full_wipe | bool
      block:

        - name: Stop docker
          service: { name: docker, state: stopped }
          failed_when: false

        # purge = supprime aussi la config / autoremove = dépendances inutiles
        - name: Uninstall docker packages
          apt:
            name: [docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin]
            state: absent
            purge: true
            autoremove: true

        # dépôt apt, clé GPG et toutes les données Docker
        - name: Remove docker repo, key and data
          file: { path: "{{ item }}", state: absent }
          loop:
            - /etc/apt/sources.list.d/docker.list
            - /etc/apt/keyrings/docker.asc
            - /var/lib/docker
            - /var/lib/containerd

        # désactive le swap
        - name: Swap off
          command: "swapoff {{ swap_file }}"
          failed_when: false

        # absent_from_fstab = retire la ligne sans essayer de démonter
        - name: Remove swap from fstab
          ansible.posix.mount:
            path: none
            src: "{{ swap_file }}"
            fstype: swap
            state: absent_from_fstab

        # supprime le fichier swap et le réglage swappiness
        - name: Delete swap file and sysctl
          file: { path: "{{ item }}", state: absent }
          loop:
            - "{{ swap_file }}"
            - /etc/sysctl.d/99-<NOM_PROJET>-swap.conf

        # remet ufw à zéro
        - name: Reset firewall
          community.general.ufw:
            state: reset

    # affiche ce qui a été fait
    - name: Summary
      debug:
        msg: "Serveur nettoyé ({{ 'TOTAL' if full_wipe | bool else 'stack + données' }})."
```
