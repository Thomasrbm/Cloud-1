# ansible.cfg

- Lu automatiquement quand tu lances `ansible-playbook` depuis ce dossier
- Évite de retaper les mêmes options à chaque commande

```ini
# section des réglages généraux
[defaults]

# inventaire utilisé par défaut (plus besoin de -i)
inventory = inventory.ini

# utilisateur SSH par défaut, écrasé par ansible_user dans l'inventaire
# sur AWS Ubuntu : ubuntu
remote_user = <SSH_USER>

# clé privée par défaut, écrasée par ansible_ssh_private_key_file
# sur AWS : le .pem de la key pair, en chmod 400
private_key_file = <CHEMIN_CLE_PRIVEE>

# ne demande pas de taper "yes" à la première connexion SSH (sinon le script bloque)
host_key_checking = False

# (facultatif) fichier contenant le mot de passe du vault -> plus besoin de --ask-vault-pass
# ce fichier ne doit JAMAIS aller sur git
# vault_password_file = <FICHIER_MDP_VAULT>

# (facultatif) dossier où chercher les rôles
# roles_path = ./roles

# section des réglages SSH
[ssh_connection]

# envoie le code directement dans la session SSH au lieu de copier un fichier
# 2 à 3x plus rapide (marche si sudo n'exige pas de tty, OK sur Ubuntu)
pipelining = True

# -C : compresse / ControlMaster : réutilise la même connexion
# ControlPersist=300s : garde la connexion ouverte 5 min entre les tâches
ssh_args = -C -o ControlMaster=auto -o ControlPersist=300s
```
