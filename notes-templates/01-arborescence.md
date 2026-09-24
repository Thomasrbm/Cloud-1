# Arborescence d'un projet Ansible

## À quoi ça sert

Ansible cherche les fichiers à des endroits précis. Si tu respectes cette structure, tout est chargé automatiquement.

## La structure

```text
<NOM_PROJET>/
  ansible.cfg
  inventory.ini
  playbook.yml
  teardown.yml
  requirements.yml
  .gitignore
  group_vars/
    all.yml
    <NOM_GROUPE>.yml
    <NOM_GROUPE>.yml.example
  roles/
    <NOM_ROLE>/
      tasks/main.yml
      handlers/main.yml
      templates/<FICHIER>.j2
      files/<FICHIER>
      defaults/main.yml
```

## Ce que fait chaque élément

- `ansible.cfg` : réglages d'Ansible (inventaire par défaut, clé SSH, vitesse)
- `inventory.ini` : liste des serveurs à configurer
- `playbook.yml` : point d'entrée, dit quels rôles lancer sur quels serveurs
- `teardown.yml` : playbook qui désinstalle tout
- `requirements.yml` : modules supplémentaires à télécharger
- `.gitignore` : fichiers à ne jamais envoyer sur git
- `group_vars/all.yml` : variables appliquées à tous les serveurs
- `group_vars/<NOM_GROUPE>.yml` : variables appliquées au groupe du même nom, ici les secrets chiffrés
- `group_vars/<NOM_GROUPE>.yml.example` : modèle des secrets en clair, sans vraies valeurs
- `roles/<NOM_ROLE>/tasks/main.yml` : la liste des actions du rôle (seul fichier obligatoire)
- `roles/<NOM_ROLE>/handlers/main.yml` : actions lancées seulement si quelque chose a changé
- `roles/<NOM_ROLE>/templates/` : fichiers `.j2` dont les variables sont remplacées avant d'être envoyés
- `roles/<NOM_ROLE>/files/` : fichiers envoyés tels quels
- `roles/<NOM_ROLE>/defaults/main.yml` : valeurs par défaut du rôle (les plus faciles à écraser)

## Créer un rôle vide

```bash
ansible-galaxy role init roles/<NOM_ROLE>
```

- Crée tous les dossiers du rôle d'un coup.

```bash
mkdir -p roles/<NOM_ROLE>/{tasks,handlers,templates,files}
```

- Même chose à la main, seulement avec les dossiers utiles.
