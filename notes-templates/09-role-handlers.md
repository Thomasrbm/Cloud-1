# roles/<NOM_ROLE>/handlers/main.yml

Exécuté **une seule fois, en fin de play**, seulement si une tâche avec `notify: <NOM_HANDLER>` a été `changed`.

```yaml
---
# Redémarrer un conteneur
- name: Restart <NOM_SERVICE>
  command: docker compose restart <NOM_SERVICE>
  args:
    chdir: "{{ project_dir }}"

# Recréer toute la stack (ex: .env modifié -> les conteneurs doivent le relire)
- name: Recreate stack
  command: docker compose up -d --force-recreate --remove-orphans
  args:
    chdir: "{{ project_dir }}"

# Recharger un service systemd sans couper les sessions
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
  notify: Restart <NOM_SERVICE>    # le nom doit correspondre EXACTEMENT
```

- Forcer l'exécution immédiate des handlers : `- meta: flush_handlers`
