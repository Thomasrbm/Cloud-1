# Projet Ansible minimal (sans templates/, sans handlers/)

- Quand l'arborescence est imposée et limitée aux `tasks/main.yml`
- Les fichiers à déposer sont écrits directement dans la tâche avec `copy: content:`
- Les redémarrages se font avec `register` + `when: ... is changed` au lieu des handlers

```text
<NOM_PROJET>/
  # réglages : inventaire, vault, clé, utilisateur -> "ansible-playbook <PLAYBOOK>.yml" suffit
  ansible.cfg
  # serveurs rangés par groupe
  inventory.ini
  # playbook principal
  <PLAYBOOK>.yml
  # variables pour TOUS les serveurs (peut contenir des valeurs chiffrées !vault)
  group_vars/all.yml
  # variables pour le groupe <NOM_GROUPE> seulement
  group_vars/<NOM_GROUPE>.yml
  # un rôle = uniquement son tasks/main.yml
  roles/<ROLE_1>/tasks/main.yml
  roles/<ROLE_2>/tasks/main.yml
  roles/<ROLE_3>/tasks/main.yml
```

## Déposer un fichier sans dossier templates/

```yaml
# copy + content : le texte est écrit directement dans la tâche
# les {{ variables }} dans content sont quand même remplacées par Ansible
- name: Deploy <FICHIER>
  copy:
    dest: <CHEMIN_SUR_LE_SERVEUR>
    owner: root
    group: root
    mode: '0644'
    # "|" = bloc de texte multi-lignes, les retours à la ligne sont gardés
    content: |
      <LIGNE_1>
      <CLE>={{ <VARIABLE> }}
      <LIGNE_3>
  # garde le résultat pour savoir si le fichier a changé
  register: <NOM_RESULTAT>
```

## Remplacer un handler (pas de dossier handlers/)

```yaml
# redémarre SEULEMENT si le fichier précédent a changé
# (sinon "changed" à chaque lancement -> pas idempotent)
- name: Restart <SERVICE> if its config changed
  systemd:
    name: <SERVICE>
    state: restarted
  when: <NOM_RESULTAT> is changed

# plusieurs fichiers peuvent déclencher le même redémarrage
- name: Restart <SERVICE> if any config changed
  systemd:
    name: <SERVICE>
    state: restarted
  when: (<RESULTAT_1> is changed) or (<RESULTAT_2> is changed)
```
