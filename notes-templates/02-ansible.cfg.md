# ansible.cfg

Lu automatiquement si présent dans le dossier où on lance `ansible-playbook`.

```ini
[defaults]
# Inventaire par défaut (évite -i à chaque commande)
inventory = inventory.ini

# Utilisateur SSH par défaut (surchargé par ansible_user dans l'inventaire)
remote_user = <SSH_USER>

# Clé privée par défaut (surchargée par ansible_ssh_private_key_file)
private_key_file = <CHEMIN_CLE_PRIVEE>

# Ne demande pas "yes" à la 1re connexion SSH
host_key_checking = False

# (optionnel) fichier contenant le mot de passe vault -> plus besoin de --ask-vault-pass
# vault_password_file = <CHEMIN_FICHIER_MDP_VAULT>

# (optionnel) où chercher les rôles
# roles_path = ./roles

[ssh_connection]
# Envoie le module dans la session SSH : 2-3x plus rapide
pipelining = True

# Garde la connexion SSH ouverte entre les tâches
ssh_args = -C -o ControlMaster=auto -o ControlPersist=300s
```

## À retenir

- `pipelining = True` nécessite que sudo n'exige pas de tty (OK sur Ubuntu).
- Sur AWS : `<SSH_USER>` = `ubuntu`, clé = `.pem` de la key pair en `chmod 400`.
- Ne JAMAIS commit `vault_password_file` → à mettre dans `.gitignore`.
