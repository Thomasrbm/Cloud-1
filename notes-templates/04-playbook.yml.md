# playbook.yml

- Point d'entrée : sur quels serveurs, avec quels droits, quels rôles dans quel ordre

```yaml
---
# nom du play, affiché au lancement
- name: <DESCRIPTION_DU_DEPLOIEMENT>

  # groupe de serveurs ciblé (défini dans inventory.ini)
  hosts: <NOM_GROUPE>

  # exécute en root via sudo (installer des paquets, pare-feu...)
  become: true

  # rôles exécutés dans l'ordre, de haut en bas
  # tags = étiquettes pour lancer un seul rôle avec --tags
  roles:
    # --- préparation de la machine ---
    # clés publiques + accès root par clé
    - { role: ssh_access, tags: ['ssh'] }
    # fichier d'échange pour les petites machines
    - { role: swap, tags: ['swap', 'system'] }
    # installe Docker + plugin compose
    - { role: docker, tags: ['docker'] }
    # pare-feu : seuls 22, 80, 443 ouverts
    - { role: ufw, tags: ['ufw', 'security'] }

    # --- un rôle = un composant de la stack ---
    # dossier projet, .env, réseau, volumes
    - { role: stack, tags: ['stack'] }
    # base de données
    - { role: <ROLE_DB>, tags: ['<TAG_DB>'] }
    # application
    - { role: <ROLE_APP>, tags: ['<TAG_APP>'] }
    # interface d'administration
    - { role: <ROLE_ADMIN>, tags: ['<TAG_ADMIN>'] }
    # nginx + TLS : le seul exposé sur Internet
    - { role: proxy, tags: ['proxy', 'nginx'] }
```

## Variante sans rôles (tout dans un fichier)

```yaml
---
- name: <DESCRIPTION>
  hosts: <NOM_GROUPE>
  become: true

  # variables définies directement dans le playbook
  vars:
    <VARIABLE>: <VALEUR>

  # liste des actions, à la place des rôles
  tasks:
    - name: <DESCRIPTION_TACHE>
      # installe un paquet
      apt:
        name: <PAQUET>
        state: present
        update_cache: true
      # appelle le handler si la tâche a changé quelque chose
      notify: <NOM_HANDLER>

  # actions lancées seulement si une tâche les appelle avec notify
  handlers:
    - name: <NOM_HANDLER>
      service:
        name: <SERVICE>
        state: restarted
```

## Lancer

```bash
# tout lancer (demande le mot de passe du vault)
ansible-playbook playbook.yml --ask-vault-pass

# seulement les rôles qui ont ce tag
ansible-playbook playbook.yml --tags <TAG> --ask-vault-pass

# tout sauf les rôles qui ont ce tag
ansible-playbook playbook.yml --skip-tags <TAG> --ask-vault-pass

# simulation : montre ce qui changerait, sans rien modifier
ansible-playbook playbook.yml --check --diff --ask-vault-pass

# seulement sur un serveur de l'inventaire
ansible-playbook playbook.yml --limit <NOM_HOTE> --ask-vault-pass
```
