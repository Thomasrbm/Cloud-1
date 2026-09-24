# roles/ssh_access (tasks + handlers)

## À quoi ça sert

- Autorise plusieurs machines (fixe, portable, poste de l'école) avec leurs clés PUBLIQUES
- Autorise `ssh root@<IP_SERVEUR>` par clé, bloqué par défaut sur les images cloud
- Le mot de passe root reste toujours refusé

## tasks/main.yml

```yaml
---
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

## Tâche par tâche

- **Authorize extra SSH public keys for the deploy user** :
  - `authorized_key:` : ajoute une clé dans `~/.ssh/authorized_keys` sans doublon
  - `user:` : utilisateur de connexion, `<SSH_USER>` si non défini
  - `lookup('file', item)` : lit le contenu du fichier `.pub`
  - `with_fileglob: "*.pub"` : boucle sur tous les `.pub` de `roles/ssh_access/files/`
- **Configure root SSH access** : bloc lancé seulement si `allow_root_ssh: true`
- **Authorize public keys for root** : mêmes clés, mais pour root
- **Check root authorized_keys** : `stat` vérifie si le fichier existe, résultat dans `root_keys`
- **Strip the cloud-image forced command** : sur AWS, la clé root est précédée de `command="echo 'Please login as ubuntu'"`, ce qui ferme la session. La regex supprime tout ce qui est avant le type de clé
- **Permit root login by key only** :
  - `PermitRootLogin prohibit-password` : root autorisé par clé, jamais par mot de passe
  - `validate: 'sshd -t -f %s'` : vérifie que la config SSH est valide avant de l'écrire
  - `notify: Restart sshd` : recharge SSH si la ligne a changé
- **Find sshd drop-in overrides** : cherche les fichiers de `/etc/ssh/sshd_config.d/`, qui ont priorité sur le fichier principal
- **Neutralize PermitRootLogin=no in drop-ins** : remplace `no` par `prohibit-password` dans ces fichiers
  - `loop_control: label` : affiche seulement le chemin dans les logs, au lieu de tout l'objet

## handlers/main.yml

```yaml
---
- name: Restart sshd
  service:
    name: ssh
    state: reloaded
```

- Recharge SSH sans couper les sessions ouvertes.

## files/<NOM_MACHINE>.pub

```text
ssh-ed25519 <CLE_PUBLIQUE_BASE64> <COMMENTAIRE>
```

- Un fichier par machine autorisée
- Uniquement des clés PUBLIQUES, jamais de clé privée
