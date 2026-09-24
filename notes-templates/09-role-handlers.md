# roles/<NOM_ROLE>/handlers/main.yml

- Tâche lancée seulement si une autre tâche l'appelle avec `notify` ET a changé quelque chose
- Exécutée une seule fois, en fin de play, même si appelée plusieurs fois

```yaml
---
# redémarre un conteneur (ex : après un changement de config nginx)
# le name doit être EXACTEMENT celui mis dans notify:
- name: Restart <NOM_SERVICE>
  command: docker compose restart <NOM_SERVICE>
  args:
    # dossier du projet, pour que compose trouve ses fichiers
    chdir: "{{ project_dir }}"

# à utiliser quand le .env change
# --force-recreate : recrée tous les conteneurs (ils ne relisent le .env qu'à leur création)
# --remove-orphans : supprime les conteneurs qui ne sont plus déclarés
- name: Recreate stack
  command: docker compose up -d --force-recreate --remove-orphans
  args:
    chdir: "{{ project_dir }}"

# recharge la config SSH sans couper les sessions ouvertes
- name: Restart sshd
  service:
    name: ssh
    state: reloaded
```

## Côté tâche

```yaml
- name: Deploy config
  template:
    src: <FICHIER>.j2
    dest: <DEST>
  # appelle le handler si le fichier a changé
  notify: Restart <NOM_SERVICE>

# (facultatif) lance les handlers en attente maintenant au lieu d'attendre la fin
- meta: flush_handlers
```
