# Rôles système complets (copier tels quels)

## roles/docker/tasks/main.yml

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

## roles/ufw/tasks/main.yml

```yaml
---
- name: Install ufw
  apt:
    name: ufw
    state: present
    update_cache: true

- name: Default deny incoming
  community.general.ufw:
    direction: incoming
    policy: deny

- name: Default allow outgoing
  community.general.ufw:
    direction: outgoing
    policy: allow

- name: Allow needed ports
  community.general.ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - "22"            # ssh  (TOUJOURS avant d'activer, sinon tu te bloques)
    - "80"            # http
    - "443"           # https
    # - "<AUTRE_PORT>"

- name: Enable ufw
  community.general.ufw:
    state: enabled
```

## roles/swap/tasks/main.yml

```yaml
---
- name: Configure a swap file
  when:
    - swap_enabled | bool
    - ansible_swaptotal_mb | int == 0     # seulement s'il n'y a aucun swap
  block:
    - name: Allocate the swap file
      command: "fallocate -l {{ swap_size_mb }}M {{ swap_file }}"
      args:
        creates: "{{ swap_file }}"
      register: swap_allocated

    - name: Restrict the swap file to root
      file:
        path: "{{ swap_file }}"
        owner: root
        group: root
        mode: "0600"

    - name: Format the swap file
      command: "mkswap {{ swap_file }}"
      when: swap_allocated.changed

    - name: Persist in /etc/fstab
      ansible.posix.mount:
        path: none
        src: "{{ swap_file }}"
        fstype: swap
        opts: sw
        state: present

    - name: Enable now
      command: "swapon {{ swap_file }}"
      when: swap_allocated.changed

    - name: Lower swappiness
      ansible.posix.sysctl:
        name: vm.swappiness
        value: "{{ swap_swappiness }}"
        state: present
        sysctl_file: /etc/sysctl.d/99-<NOM_PROJET>-swap.conf
        reload: true
```

## roles/ssh_access/tasks/main.yml

```yaml
---
# Toutes les clés PUBLIQUES de roles/ssh_access/files/*.pub
- name: Authorize extra SSH public keys for the deploy user
  ansible.posix.authorized_key:
    user: "{{ ansible_user | default('<SSH_USER>') }}"
    key: "{{ lookup('file', item) }}"
    state: present
  with_fileglob:
    - "*.pub"

- name: Configure root SSH access
  when: allow_root_ssh | bool
  block:
    - name: Authorize public keys for root
      ansible.posix.authorized_key:
        user: root
        key: "{{ lookup('file', item) }}"
        state: present
      with_fileglob:
        - "*.pub"

    - name: Check root authorized_keys
      stat:
        path: /root/.ssh/authorized_keys
      register: root_keys

    # Retire le command="echo 'Please login as ubuntu'" des images cloud
    - name: Strip the cloud-image forced command
      replace:
        path: /root/.ssh/authorized_keys
        regexp: '^.*?((?:ssh-rsa|ssh-ed25519|ssh-dss|ecdsa-sha2-\S+)\s)'
        replace: '\1'
      when: root_keys.stat.exists

    - name: Permit root login by key only
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?\s*PermitRootLogin'
        line: 'PermitRootLogin prohibit-password'
        validate: 'sshd -t -f %s'
      notify: Restart sshd

    - name: Find sshd drop-in overrides
      find:
        paths: /etc/ssh/sshd_config.d
        patterns: '*.conf'
      register: sshd_dropins

    - name: Neutralize PermitRootLogin=no in drop-ins
      replace:
        path: "{{ item.path }}"
        regexp: '^\s*PermitRootLogin\s+no\s*$'
        replace: 'PermitRootLogin prohibit-password'
      loop: "{{ sshd_dropins.files }}"
      loop_control:
        label: "{{ item.path }}"
      notify: Restart sshd
```

## roles/stack/tasks/main.yml (socle : dossier + .env + compose de base)

```yaml
---
- name: Create project directory
  file:
    path: "{{ project_dir }}"
    state: directory
    mode: '0755'

- name: Deploy .env file (secrets)
  template:
    src: env.j2
    dest: "{{ project_dir }}/.env"
    mode: '0600'
  notify: Recreate stack

- name: Deploy base compose file
  template:
    src: docker-compose.yml.j2
    dest: "{{ project_dir }}/docker-compose.yml"
    mode: '0644'
  notify: Recreate stack
```
