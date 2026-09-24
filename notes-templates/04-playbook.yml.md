# playbook.yml

## À quoi ça sert

C'est le point d'entrée. Il dit : sur quels serveurs, avec quels droits, et quels rôles lancer dans quel ordre.

## Le fichier

```yaml
---
- name: <DESCRIPTION_DU_DEPLOIEMENT>
  hosts: <NOM_GROUPE>
  become: true

  roles:
    - { role: ssh_access, tags: ['ssh'] }
    - { role: swap, tags: ['swap', 'system'] }
    - { role: docker, tags: ['docker'] }
    - { role: ufw, tags: ['ufw', 'security'] }
    - { role: stack, tags: ['stack'] }
    - { role: <ROLE_DB>, tags: ['<TAG_DB>'] }
    - { role: <ROLE_APP>, tags: ['<TAG_APP>'] }
    - { role: <ROLE_ADMIN>, tags: ['<TAG_ADMIN>'] }
    - { role: proxy, tags: ['proxy', 'nginx'] }
```

## Ligne par ligne

- `---` : début d'un document YAML (facultatif mais conventionnel)
- `- name: ...` : nom du play, affiché au lancement
- `hosts: <NOM_GROUPE>` : groupe de serveurs ciblé, défini dans `inventory.ini`
- `become: true` : exécute en root via sudo. Nécessaire pour installer des paquets ou toucher au pare-feu
- `roles:` : liste des rôles, exécutés dans l'ordre de haut en bas
- `role: ssh_access` : autorise les clés publiques et l'accès root par clé
- `role: swap` : ajoute un fichier d'échange sur les petites machines
- `role: docker` : installe Docker et le plugin compose
- `role: ufw` : pare-feu, ne laisse ouverts que 22, 80 et 443
- `role: stack` : crée le dossier du projet, le `.env`, le réseau et les volumes
- `role: <ROLE_DB>` : lance la base de données
- `role: <ROLE_APP>` : lance l'application
- `role: <ROLE_ADMIN>` : lance l'interface d'administration
- `role: proxy` : lance nginx avec le HTTPS, le seul service exposé sur Internet
- `tags: [...]` : étiquettes pour lancer un seul rôle avec `--tags`

## Variante sans rôles (tout dans un fichier)

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

- `vars:` : variables définies directement dans le playbook
- `tasks:` : liste des actions, à la place des rôles
- `apt:` : module qui installe un paquet
- `handlers:` : actions lancées seulement si une tâche les appelle avec `notify`

## Lancer le playbook

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

- Lance tout. Demande le mot de passe du vault pour déchiffrer les secrets.

```bash
ansible-playbook playbook.yml --tags <TAG> --ask-vault-pass
```

- Lance seulement les rôles qui ont ce tag.

```bash
ansible-playbook playbook.yml --skip-tags <TAG>
```

- Lance tout sauf les rôles qui ont ce tag.

```bash
ansible-playbook playbook.yml --check --diff
```

- Simulation : montre ce qui changerait, sans rien modifier.

```bash
ansible-playbook playbook.yml --limit <NOM_HOTE>
```

- Lance seulement sur un serveur de l'inventaire.
