# Arborescence d'un projet Ansible

- Ansible charge automatiquement les fichiers s'ils sont à ces emplacements

```text
<NOM_PROJET>/
  ansible.cfg                      # réglages d'Ansible (inventaire, clé SSH, vitesse)
  inventory.ini                    # liste des serveurs
  playbook.yml                     # point d'entrée : quels rôles sur quels serveurs
  teardown.yml                     # playbook de désinstallation
  requirements.yml                 # collections à télécharger (ufw, posix...)
  .gitignore                       # fichiers à ne jamais pousser sur git
  group_vars/
    all.yml                        # variables en clair pour TOUS les serveurs
    <NOM_GROUPE>.yml               # secrets chiffrés (vault) pour le groupe du même nom
    <NOM_GROUPE>.yml.example       # modèle des secrets, avec de fausses valeurs
  roles/
    <NOM_ROLE>/
      tasks/main.yml               # actions du rôle (seul fichier obligatoire)
      handlers/main.yml            # actions lancées seulement si notify + changement
      templates/<FICHIER>.j2       # fichiers dont les {{ variables }} sont remplacées
      files/<FICHIER>              # fichiers copiés tels quels
      defaults/main.yml            # valeurs par défaut du rôle (priorité la plus basse)
```

```bash
# crée toute l'arborescence d'un rôle d'un coup
ansible-galaxy role init roles/<NOM_ROLE>

# ou à la main, seulement les dossiers utiles
mkdir -p roles/<NOM_ROLE>/{tasks,handlers,templates,files}
```
