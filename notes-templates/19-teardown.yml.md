# teardown.yml

## À quoi ça sert

Remet le serveur à zéro pour rejouer le déploiement. Deux niveaux :

- Standard : supprime les conteneurs, images et données. Docker reste installé
- Total (`-e full_wipe=true`) : désinstalle aussi Docker, le swap et réinitialise le pare-feu

## Début du fichier

```yaml
---
- name: Teardown <NOM_PROJET>
  hosts: <NOM_GROUPE>
  become: true

  vars:
    full_wipe: false

  vars_prompt:
    - name: confirm
      prompt: "Effacer la stack et TOUTES les données sur {{ ansible_play_hosts | join(', ') }} ? (tape: oui)"
      private: false

  tasks:
```

- `vars: full_wipe: false` : niveau standard par défaut
- `vars_prompt:` : pose une question avant de commencer
- `private: false` : la réponse s'affiche à l'écran
- `ansible_play_hosts` : liste des serveurs visés, affichée dans la question

## Garde-fous

```yaml
    - name: Abort unless confirmed
      assert:
        that: [ "confirm | lower in ['oui', 'yes', 'y']" ]
        fail_msg: "Annulé : rien n'a été supprimé."
        quiet: true

    - name: Refuse to delete a dangerous path
      assert:
        that:
          - project_dir is defined
          - project_dir | length > 4
          - project_dir.startswith('/')
          - project_dir not in ['/', '/root', '/home', '/etc', '/var', '/usr', '/opt']
        fail_msg: "project_dir suspect : abandon."
        quiet: true

    - name: Check whether docker is installed
      command: docker --version
      register: docker_present
      changed_when: false
      failed_when: false
```

- **Abort unless confirmed** : arrête tout si la réponse n'est pas oui
- **Refuse to delete a dangerous path** : empêche de supprimer `/` ou un dossier système si `project_dir` est mal réglé
- **Check whether docker is installed** : `docker_present.rc == 0` si Docker est là

## Suppression de la stack

```yaml
    - name: Check for compose file
      stat:
        path: "{{ project_dir }}/docker-compose.yml"
      register: compose_file

    - name: Stop and remove containers, volumes, images
      command: docker compose down -v --remove-orphans --rmi all
      args:
        chdir: "{{ project_dir }}"
      when: [ compose_file.stat.exists, docker_present.rc == 0 ]
      failed_when: false

    - name: Remove named volumes explicitly
      command: "docker volume rm {{ item }}"
      loop:
        - "{{ project_dir | basename }}_<NOM_VOLUME_DB>"
        - "{{ project_dir | basename }}_<NOM_VOLUME_APP>"
      when: docker_present.rc == 0
      failed_when: false

    - name: Remove project directory
      file:
        path: "{{ project_dir }}"
        state: absent

    - name: Prune docker
      command: docker system prune -af --volumes
      when: docker_present.rc == 0
      failed_when: false
```

- **Check for compose file** : vérifie que le projet existe encore
- `down` : arrête et supprime les conteneurs et le réseau
- `-v` : supprime aussi les volumes (les données)
- `--rmi all` : supprime aussi les images
- **Remove named volumes explicitly** : filet de sécurité si le `.env` avait disparu
- `project_dir | basename` : dernier morceau du chemin (ex : `wordpress`), préfixe des volumes
- **Remove project directory** : supprime config, certificats et fichiers compose
- `system prune -af --volumes` : nettoie tout ce que Docker garde encore (cache, images, réseaux)

## Désinstallation totale

```yaml
    - name: Full wipe
      when: full_wipe | bool
      block:
        - name: Stop docker
          service: { name: docker, state: stopped }
          failed_when: false

        - name: Uninstall docker packages
          apt:
            name: [docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin]
            state: absent
            purge: true
            autoremove: true

        - name: Remove docker repo, key and data
          file: { path: "{{ item }}", state: absent }
          loop:
            - /etc/apt/sources.list.d/docker.list
            - /etc/apt/keyrings/docker.asc
            - /var/lib/docker
            - /var/lib/containerd

        - name: Swap off
          command: "swapoff {{ swap_file }}"
          failed_when: false

        - name: Remove swap from fstab
          ansible.posix.mount:
            path: none
            src: "{{ swap_file }}"
            fstype: swap
            state: absent_from_fstab

        - name: Delete swap file and sysctl
          file: { path: "{{ item }}", state: absent }
          loop:
            - "{{ swap_file }}"
            - /etc/sysctl.d/99-<NOM_PROJET>-swap.conf

        - name: Reset firewall
          community.general.ufw:
            state: reset

    - name: Summary
      debug:
        msg: "Serveur nettoyé ({{ 'TOTAL' if full_wipe | bool else 'stack + données' }})."
```

- `when: full_wipe | bool` : seulement avec `-e full_wipe=true`
- **Stop docker** : arrête le service
- **Uninstall docker packages** : `purge` supprime aussi la config, `autoremove` les dépendances inutiles
- **Remove docker repo, key and data** : dépôt apt, clé GPG et toutes les données Docker
- **Swap off** : désactive le swap
- **Remove swap from fstab** : `absent_from_fstab` retire la ligne sans essayer de démonter
- **Delete swap file and sysctl** : supprime le fichier et le réglage swappiness
- **Reset firewall** : remet ufw à zéro
- **Summary** : affiche ce qui a été fait

## Lancer

```bash
ansible-playbook teardown.yml --ask-vault-pass
```

- Niveau standard.

```bash
ansible-playbook teardown.yml --ask-vault-pass -e full_wipe=true
```

- Niveau total. `--ask-vault-pass` reste nécessaire car Ansible charge le vault du groupe.
