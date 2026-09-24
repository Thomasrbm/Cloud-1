# group_vars/<NOM_GROUPE>.yml (secrets chiffrés)

## Contenu en clair (avant chiffrement) — aussi le `.example`

```yaml
---
<DB>_root_password: <MDP_ROOT_DB>
<DB>_database: <NOM_BASE>
<DB>_user: <USER_DB>
<DB>_password: <MDP_USER_DB>

app_admin_password: <MDP_ADMIN_APP>
```

## Une fois chiffré, le fichier ressemble à

```
$ANSIBLE_VAULT;1.1;AES256
3062633733353063343034373765...
```
→ peut être commit sans risque. Seul le **mot de passe du vault** doit rester secret.

## Commandes vault

```sh
# Générer un mot de passe fort
openssl rand -base64 24

# Chiffrer / déchiffrer / éditer / voir
ansible-vault encrypt group_vars/<NOM_GROUPE>.yml
ansible-vault decrypt group_vars/<NOM_GROUPE>.yml
ansible-vault edit    group_vars/<NOM_GROUPE>.yml
ansible-vault view    group_vars/<NOM_GROUPE>.yml
ansible-vault rekey   group_vars/<NOM_GROUPE>.yml     # changer le mdp vault

# Chiffrer une seule valeur (à coller dans un yml en clair)
ansible-vault encrypt_string '<SECRET>' --name '<NOM_VARIABLE>'

# Lancer le playbook
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --vault-password-file <FICHIER_MDP_VAULT>
```

## Chemin d'un secret

`group_vars/<NOM_GROUPE>.yml` (vault) → `{{ variable }}` dans `env.j2` → `.env` sur le serveur (mode 0600) → `${VARIABLE}` dans les compose → variables d'env du conteneur.
