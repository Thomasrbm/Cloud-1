# ansible.cfg

## À quoi ça sert

Fichier de réglages lu automatiquement quand tu lances `ansible-playbook` depuis ce dossier. Il évite de retaper les mêmes options à chaque commande.

## Le fichier

```ini
[defaults]
inventory = inventory.ini
remote_user = <SSH_USER>
private_key_file = <CHEMIN_CLE_PRIVEE>
host_key_checking = False

[ssh_connection]
pipelining = True
ssh_args = -C -o ControlMaster=auto -o ControlPersist=300s
```

## Ligne par ligne

- `[defaults]` : début de la section des réglages généraux
- `inventory = inventory.ini` : fichier de serveurs utilisé par défaut, plus besoin de `-i`
- `remote_user = <SSH_USER>` : utilisateur SSH par défaut. Écrasé par `ansible_user` dans l'inventaire. Sur AWS Ubuntu : `ubuntu`
- `private_key_file = <CHEMIN_CLE_PRIVEE>` : clé privée par défaut. Sur AWS : le `.pem`, en `chmod 400`
- `host_key_checking = False` : ne demande pas de taper "yes" à la première connexion SSH, sinon le script bloque
- `[ssh_connection]` : début de la section des réglages SSH
- `pipelining = True` : envoie le code directement dans la session SSH au lieu de copier un fichier. 2 à 3 fois plus rapide
- `ssh_args = -C ...` : `-C` compresse, `ControlMaster=auto` réutilise la même connexion, `ControlPersist=300s` la garde ouverte 5 minutes

## Options facultatives

```ini
vault_password_file = <FICHIER_MDP_VAULT>
roles_path = ./roles
```

- `vault_password_file` : lit le mot de passe du vault dans un fichier, plus besoin de `--ask-vault-pass`. Ce fichier ne doit jamais aller sur git
- `roles_path` : dossier où chercher les rôles
