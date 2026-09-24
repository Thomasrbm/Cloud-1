# group_vars/<NOM_GROUPE>.yml (secrets chiffrés)

## À quoi ça sert

Contient les mots de passe. Il est chiffré avec `ansible-vault` (AES-256), donc il peut aller sur git. Seul le mot de passe du vault doit rester secret.

## Le contenu en clair, avant chiffrement

```yaml
---
<DB>_root_password: <MDP_ROOT_DB>
<DB>_database: <NOM_BASE>
<DB>_user: <USER_DB>
<DB>_password: <MDP_USER_DB>
app_admin_password: <MDP_ADMIN_APP>
```

## Ligne par ligne

- `<DB>_root_password` : mot de passe root de la base de données
- `<DB>_database` : nom de la base créée au premier démarrage
- `<DB>_user` : utilisateur de la base utilisé par l'application
- `<DB>_password` : mot de passe de cet utilisateur
- `app_admin_password` : mot de passe du compte admin de l'application

Copie ce même contenu dans `<NOM_GROUPE>.yml.example` avec de fausses valeurs, pour servir de modèle.

## À quoi ressemble le fichier une fois chiffré

```text
$ANSIBLE_VAULT;1.1;AES256
3062633733353063343034373765...
```

- Première ligne : format du vault et algorithme utilisé
- Le reste : le contenu chiffré, illisible sans le mot de passe

## Commandes

```bash
openssl rand -base64 24
```

- Génère un mot de passe aléatoire solide.

```bash
ansible-vault encrypt group_vars/<NOM_GROUPE>.yml
```

- Chiffre le fichier. Demande un mot de passe de vault.

```bash
ansible-vault edit group_vars/<NOM_GROUPE>.yml
```

- Ouvre le fichier déchiffré dans l'éditeur, puis le rechiffre à la fermeture.

```bash
ansible-vault view group_vars/<NOM_GROUPE>.yml
```

- Affiche le contenu sans le modifier.

```bash
ansible-vault decrypt group_vars/<NOM_GROUPE>.yml
```

- Remet le fichier en clair sur le disque. À éviter.

```bash
ansible-vault rekey group_vars/<NOM_GROUPE>.yml
```

- Change le mot de passe du vault.

```bash
ansible-vault encrypt_string '<SECRET>' --name '<NOM_VARIABLE>'
```

- Chiffre une seule valeur, à coller dans un fichier en clair.

## Le chemin d'un secret

1. Écrit chiffré dans `group_vars/<NOM_GROUPE>.yml`
2. Déchiffré en mémoire par Ansible grâce à `--ask-vault-pass`
3. Injecté dans `env.j2` avec `{{ variable }}`
4. Écrit dans `<PROJECT_DIR>/.env` sur le serveur, lisible seulement par root
5. Lu par docker compose avec `${VARIABLE}`
6. Transmis au conteneur comme variable d'environnement
