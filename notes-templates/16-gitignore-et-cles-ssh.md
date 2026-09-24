# .gitignore + clés SSH

## .gitignore

```gitignore
# Le vault chiffré (group_vars/<NOM_GROUPE>.yml) PEUT être commit.
# Ce qui ne doit JAMAIS l'être : clés privées et mot de passe du vault.
*.pem
*.key
*.retry
vault_pass.txt
<FICHIER_MDP_VAULT>
.env
```

## roles/ssh_access/files/<MACHINE>.pub

Un fichier `.pub` par machine autorisée (PUBLIQUE uniquement) :

```
ssh-ed25519 <CLE_PUBLIQUE_BASE64> <COMMENTAIRE>
```

## Générer / récupérer une clé

```sh
ssh-keygen -t ed25519 -C "<NOM_MACHINE>"
cat ~/.ssh/id_ed25519.pub        # -> coller dans roles/ssh_access/files/<NOM_MACHINE>.pub
chmod 400 <CHEMIN_CLE_PRIVEE>    # clé .pem AWS
ssh -i <CHEMIN_CLE_PRIVEE> <SSH_USER>@<IP_SERVEUR>
ssh root@<IP_SERVEUR>            # après le rôle ssh_access
```

## ~/.ssh/config (optionnel, raccourci)

```
Host <ALIAS>
    HostName <IP_SERVEUR>
    User <SSH_USER>
    IdentityFile <CHEMIN_CLE_PRIVEE>
```
