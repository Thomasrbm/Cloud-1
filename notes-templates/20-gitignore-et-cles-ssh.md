# .gitignore et clés SSH

## .gitignore

```gitignore
# le vault chiffré group_vars/<NOM_GROUPE>.yml PEUT aller sur git
# ce qui ne doit JAMAIS y aller : clés privées et mot de passe du vault

# clés privées AWS
*.pem
# autres clés privées
*.key
# fichiers créés par Ansible après un échec
*.retry
# secrets en clair
.env
# mot de passe du vault
vault_pass.txt
<FICHIER_MDP_VAULT>
```

## Commandes clés SSH

```bash
# crée une paire de clés (privée + publique) sur ta machine
ssh-keygen -t ed25519 -C "<NOM_MACHINE>"

# affiche la clé publique -> à coller dans roles/ssh_access/files/<NOM_MACHINE>.pub
cat ~/.ssh/id_ed25519.pub

# rend la clé lisible seulement par toi (SSH refuse une clé trop ouverte)
chmod 400 <CHEMIN_CLE_PRIVEE>

# connexion avec une clé précise
ssh -i <CHEMIN_CLE_PRIVEE> <SSH_USER>@<IP_SERVEUR>

# connexion en root (après le rôle ssh_access)
ssh root@<IP_SERVEUR>
```

## ~/.ssh/config (raccourci)

```text
# ensuite "ssh <ALIAS>" suffit
Host <ALIAS>
    # vraie adresse
    HostName <IP_SERVEUR>
    # utilisateur
    User <SSH_USER>
    # clé à utiliser
    IdentityFile <CHEMIN_CLE_PRIVEE>
```
