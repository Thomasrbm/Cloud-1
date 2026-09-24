# Vault : chiffrer UNE variable + fichier de mot de passe

- Utile quand un fichier de variables mélange valeurs en clair et secret
- Seule la valeur secrète est chiffrée, le reste reste lisible

## Chiffrer une seule valeur

```bash
# affiche un bloc "!vault |" à coller dans le fichier de variables
# attention : la commande reste dans l'historique du shell -> préférer la 2e forme
ansible-vault encrypt_string '<VALEUR_SECRETE>' --name '<NOM_VARIABLE>'

# demande la valeur au clavier (rien dans l'historique)
ansible-vault encrypt_string --stdin-name '<NOM_VARIABLE>'
```

## group_vars/all.yml avec une valeur chiffrée

```yaml
---
# valeur en clair
<VARIABLE_EN_CLAIR>: <VALEUR>

# valeur chiffrée : "!vault |" puis le bloc copié depuis encrypt_string
<NOM_VARIABLE>: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  <BLOC_CHIFFRE_LIGNE_1>
  <BLOC_CHIFFRE_LIGNE_2>
```

```bash
# vérifier la valeur déchiffrée
ansible localhost -m debug -a "var=<NOM_VARIABLE>" -e "@group_vars/all.yml"
```

## ansible.cfg : ne plus taper d'option

```ini
[defaults]
inventory = inventory.ini

# OPTION A : demande le mot de passe du vault à chaque lancement
ask_vault_pass = True

# OPTION B : lit le mot de passe dans un fichier NON versionné (prend le pas sur A)
# vault_password_file = <CHEMIN_FICHIER_MDP_VAULT>
```

## Fichier de mot de passe du vault

```bash
# crée le fichier avec un mot de passe aléatoire
openssl rand -base64 32 > <CHEMIN_FICHIER_MDP_VAULT>

# lisible seulement par toi
chmod 600 <CHEMIN_FICHIER_MDP_VAULT>

# JAMAIS sur git
echo "<NOM_FICHIER_MDP_VAULT>" >> .gitignore

# vérifier qu'il est bien ignoré
git check-ignore -v <CHEMIN_FICHIER_MDP_VAULT>
```

- Hors du repo (ex : `~/.vault_pass`) = encore plus sûr que dans le repo + `.gitignore`
