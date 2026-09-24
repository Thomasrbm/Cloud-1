# group_vars/<NOM_GROUPE>.yml (secrets chiffrés)

- Contient les mots de passe, chiffré avec ansible-vault (AES-256)
- Peut aller sur git une fois chiffré
- Seul le mot de passe du vault doit rester secret
- Même contenu avec de fausses valeurs dans `<NOM_GROUPE>.yml.example`

```yaml
---
# mot de passe root de la base de données
<DB>_root_password: <MDP_ROOT_DB>

# nom de la base créée au premier démarrage
<DB>_database: <NOM_BASE>

# utilisateur de la base utilisé par l'application
<DB>_user: <USER_DB>

# mot de passe de cet utilisateur
<DB>_password: <MDP_USER_DB>

# mot de passe du compte admin de l'application
app_admin_password: <MDP_ADMIN_APP>
```

## Une fois chiffré

```text
$ANSIBLE_VAULT;1.1;AES256
3062633733353063343034373765...
```

- 1re ligne : format du vault + algorithme
- Le reste : contenu illisible sans le mot de passe

## Commandes

```bash
# génère un mot de passe aléatoire solide
openssl rand -base64 24

# chiffre le fichier (demande un mot de passe de vault)
ansible-vault encrypt group_vars/<NOM_GROUPE>.yml

# ouvre le fichier déchiffré dans l'éditeur, le rechiffre à la fermeture
ansible-vault edit group_vars/<NOM_GROUPE>.yml

# affiche le contenu sans le modifier
ansible-vault view group_vars/<NOM_GROUPE>.yml

# remet le fichier en clair sur le disque (à éviter)
ansible-vault decrypt group_vars/<NOM_GROUPE>.yml

# change le mot de passe du vault
ansible-vault rekey group_vars/<NOM_GROUPE>.yml

# chiffre une seule valeur, à coller dans un fichier en clair
ansible-vault encrypt_string '<SECRET>' --name '<NOM_VARIABLE>'
```

## Chemin d'un secret

1. Chiffré dans `group_vars/<NOM_GROUPE>.yml`
2. Déchiffré en mémoire par Ansible (`--ask-vault-pass`)
3. Injecté dans `env.j2` avec `{{ variable }}`
4. Écrit dans `<PROJECT_DIR>/.env` sur le serveur (lisible par root seulement)
5. Lu par docker compose avec `${VARIABLE}`
6. Transmis au conteneur comme variable d'environnement
