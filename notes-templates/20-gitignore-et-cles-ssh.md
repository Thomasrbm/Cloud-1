# .gitignore et clés SSH

## .gitignore

```gitignore
*.pem
*.key
*.retry
.env
vault_pass.txt
<FICHIER_MDP_VAULT>
```

- `*.pem` : clés privées AWS
- `*.key` : autres clés privées
- `*.retry` : fichiers créés par Ansible après un échec
- `.env` : fichier de secrets en clair
- `vault_pass.txt` / `<FICHIER_MDP_VAULT>` : mot de passe du vault
- Le vault chiffré `group_vars/<NOM_GROUPE>.yml` peut, lui, aller sur git

## Fichier de clé publique

```text
ssh-ed25519 <CLE_PUBLIQUE_BASE64> <COMMENTAIRE>
```

- `ssh-ed25519` : type de clé
- `<CLE_PUBLIQUE_BASE64>` : la clé elle-même
- `<COMMENTAIRE>` : nom de la machine, pour s'y retrouver
- Un fichier `.pub` par machine dans `roles/ssh_access/files/`

## Commandes

```bash
ssh-keygen -t ed25519 -C "<NOM_MACHINE>"
```

- Crée une paire de clés (privée + publique) sur ta machine.

```bash
cat ~/.ssh/id_ed25519.pub
```

- Affiche la clé publique, à coller dans `roles/ssh_access/files/<NOM_MACHINE>.pub`.

```bash
chmod 400 <CHEMIN_CLE_PRIVEE>
```

- Rend la clé lisible seulement par toi. SSH refuse une clé trop ouverte.

```bash
ssh -i <CHEMIN_CLE_PRIVEE> <SSH_USER>@<IP_SERVEUR>
```

- Connexion avec une clé précise.

```bash
ssh root@<IP_SERVEUR>
```

- Connexion en root, possible après le rôle ssh_access.

## Raccourci dans ~/.ssh/config

```text
Host <ALIAS>
    HostName <IP_SERVEUR>
    User <SSH_USER>
    IdentityFile <CHEMIN_CLE_PRIVEE>
```

- `Host` : surnom à taper, ensuite `ssh <ALIAS>` suffit
- `HostName` : vraie adresse
- `User` : utilisateur
- `IdentityFile` : clé à utiliser
