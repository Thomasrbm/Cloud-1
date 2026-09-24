# playbook.yml

```yaml
---
- name: <DESCRIPTION_DU_DEPLOIEMENT>
  hosts: <NOM_GROUPE>        # groupe défini dans inventory.ini
  become: true               # sudo (installer paquets, pare-feu...)

  roles:
    # --- préparation de la machine ---
    - { role: ssh_access, tags: ['ssh'] }
    - { role: swap,       tags: ['swap', 'system'] }
    - { role: docker,     tags: ['docker'] }
    - { role: ufw,        tags: ['ufw', 'security'] }

    # --- un rôle = un composant de la stack ---
    - { role: stack,      tags: ['stack'] }       # dossier, .env, réseau, volumes
    - { role: <ROLE_DB>,    tags: ['<TAG_DB>'] }
    - { role: <ROLE_APP>,   tags: ['<TAG_APP>'] }
    - { role: <ROLE_ADMIN>, tags: ['<TAG_ADMIN>'] }
    - { role: proxy,      tags: ['proxy', 'nginx'] } # seul exposé sur Internet
```

## Variante avec tâches directes (sans rôles)

```yaml
---
- name: <DESCRIPTION>
  hosts: <NOM_GROUPE>
  become: true
  vars:
    <VARIABLE>: <VALEUR>
  tasks:
    - name: <DESCRIPTION_TACHE>
      apt:
        name: <PAQUET>
        state: present
        update_cache: true
  handlers:
    - name: <NOM_HANDLER>
      service:
        name: <SERVICE>
        state: restarted
```

## Lancer

```sh
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --tags <TAG> --ask-vault-pass    # un seul rôle
ansible-playbook playbook.yml --skip-tags <TAG>
ansible-playbook playbook.yml --check --diff                   # dry-run
ansible-playbook playbook.yml --limit <NOM_HOTE>               # un seul hôte
```
