# roles/<NOM_ROLE>/handlers/main.yml

## À quoi ça sert

Un handler est une tâche qui ne s'exécute que si une autre tâche l'appelle avec `notify` ET a changé quelque chose. Il s'exécute une seule fois, à la fin du play, même s'il est appelé plusieurs fois.

## Le fichier

```yaml
---
- name: Restart <NOM_SERVICE>
  command: docker compose restart <NOM_SERVICE>
  args:
    chdir: "{{ project_dir }}"

- name: Recreate stack
  command: docker compose up -d --force-recreate --remove-orphans
  args:
    chdir: "{{ project_dir }}"

- name: Restart sshd
  service:
    name: ssh
    state: reloaded
```

## Ligne par ligne

- `name: Restart <NOM_SERVICE>` : nom exact à mettre dans `notify:`
- `docker compose restart <NOM_SERVICE>` : redémarre le conteneur, par exemple après un changement de config nginx
- `chdir:` : se place dans le dossier du projet pour que compose trouve ses fichiers
- `name: Recreate stack` : à utiliser quand le `.env` change
- `up -d --force-recreate` : recrée tous les conteneurs. Nécessaire car un conteneur ne relit le `.env` qu'à sa création
- `--remove-orphans` : supprime les conteneurs qui ne sont plus dans les fichiers compose
- `name: Restart sshd` : recharge la config SSH
- `state: reloaded` : relit la config sans couper les sessions ouvertes

## Côté tâche qui appelle le handler

```yaml
- name: Deploy config
  template:
    src: <FICHIER>.j2
    dest: <DEST>
  notify: Restart <NOM_SERVICE>
```

- `notify:` : doit contenir exactement le `name` du handler

## Forcer les handlers tout de suite

```yaml
- meta: flush_handlers
```

- Lance les handlers en attente maintenant, au lieu d'attendre la fin du play.
