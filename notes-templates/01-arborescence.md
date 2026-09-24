# Arborescence d'un projet Ansible

```
<NOM_PROJET>/
├── ansible.cfg                 # config ansible (inventaire, clé, ssh)
├── inventory.ini               # liste des serveurs
├── playbook.yml                # point d'entrée : liste des rôles
├── teardown.yml                # désinstallation
├── requirements.yml            # collections galaxy
├── .gitignore
├── group_vars/
│   ├── all.yml                 # variables en clair (tous les hôtes)
│   ├── <NOM_GROUPE>.yml        # secrets CHIFFRÉS (ansible-vault)
│   └── <NOM_GROUPE>.yml.example# modèle en clair des secrets
└── roles/
    └── <NOM_ROLE>/
        ├── tasks/main.yml      # ce que fait le rôle (obligatoire)
        ├── handlers/main.yml   # actions déclenchées par notify
        ├── templates/*.j2      # fichiers Jinja2 (variables remplacées)
        ├── files/              # fichiers copiés tels quels
        └── defaults/main.yml   # variables par défaut (priorité la + basse)
```

## Créer un rôle vide

```sh
ansible-galaxy role init roles/<NOM_ROLE>
# ou à la main :
mkdir -p roles/<NOM_ROLE>/{tasks,handlers,templates,files}
```

## Chargement automatique

- `group_vars/all.yml` → appliqué à **tous** les hôtes
- `group_vars/<NOM_GROUPE>.yml` → appliqué au groupe du même nom dans l'inventaire
- `template: src: x.j2` → cherché dans `roles/<NOM_ROLE>/templates/`
- `copy: src: x` / `lookup('file', ...)` → cherché dans `roles/<NOM_ROLE>/files/`
