# teardown.yml (désinstallation)

```yaml
---
# ansible-playbook teardown.yml --ask-vault-pass                    # stack + données
# ansible-playbook teardown.yml --ask-vault-pass -e full_wipe=true  # + docker, swap, ufw
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
