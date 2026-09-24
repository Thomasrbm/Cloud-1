# roles/ssh_access (tasks + handlers + files)

- Autorise plusieurs machines avec leurs clés PUBLIQUES
- Autorise `ssh root@<IP_SERVEUR>` par clé (bloqué par défaut sur les images cloud)
- Mot de passe root toujours refusé

## tasks/main.yml

```yaml
---
# ------------------------------------------------------------------------------
# Bloc 1 : clés publiques pour l'utilisateur de déploiement
# ------------------------------------------------------------------------------
# authorized_key : ajoute une clé dans ~/.ssh/authorized_keys, sans doublon
# lookup('file', item) : lit le contenu du fichier .pub
# with_fileglob "*.pub" : boucle sur tous les .pub de roles/ssh_access/files/
- name: Authorize extra SSH public keys for the deploy user
  ansible.posix.authorized_key:
    user: "{{ ansible_user | default('<SSH_USER>') }}"
    key: "{{ lookup('file', item) }}"
    state: present
  with_fileglob:
    - "*.pub"


# ------------------------------------------------------------------------------
# Bloc 2 : accès root par clé (seulement si allow_root_ssh: true)
# ------------------------------------------------------------------------------
- name: Configure root SSH access
  when: allow_root_ssh | bool
  block:

    # mêmes clés, mais pour root
    - name: Authorize public keys for root
      ansible.posix.authorized_key:
        user: root
        key: "{{ lookup('file', item) }}"
        state: present
      with_fileglob:
        - "*.pub"

    # vérifie si /root/.ssh/authorized_keys existe (résultat dans root_keys)
    - name: Check root authorized_keys
      stat:
        path: /root/.ssh/authorized_keys
      register: root_keys

    # sur AWS la clé root est précédée de command="echo 'Please login as ubuntu'"
    # qui ferme la session : on supprime tout ce qui est avant le type de clé
    - name: Strip the cloud-image forced command
      replace:
        path: /root/.ssh/authorized_keys
        regexp: '^.*?((?:ssh-rsa|ssh-ed25519|ssh-dss|ecdsa-sha2-\S+)\s)'
        replace: '\1'
      when: root_keys.stat.exists

    # root autorisé par clé, jamais par mot de passe
    # validate : vérifie que la config SSH est valide avant de l'écrire
    - name: Permit root login by key only
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?\s*PermitRootLogin'
        line: 'PermitRootLogin prohibit-password'
        validate: 'sshd -t -f %s'
      notify: Restart sshd

    # les fichiers de /etc/ssh/sshd_config.d/ ont priorité sur le fichier principal
    - name: Find sshd drop-in overrides
      find:
        paths: /etc/ssh/sshd_config.d
        patterns: '*.conf'
      register: sshd_dropins

    # remplace "PermitRootLogin no" dans ces fichiers
    # loop_control label : affiche seulement le chemin dans les logs
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

## handlers/main.yml

```yaml
---
# recharge SSH sans couper les sessions ouvertes
- name: Restart sshd
  service:
    name: ssh
    state: reloaded
```

## files/<NOM_MACHINE>.pub

```text
ssh-ed25519 <CLE_PUBLIQUE_BASE64> <COMMENTAIRE>
```

- Un fichier par machine autorisée
- Uniquement des clés PUBLIQUES, jamais de clé privée
