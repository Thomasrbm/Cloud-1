# inventory.ini

- Liste des serveurs qu'Ansible va configurer, rangés par groupes
- Le playbook cible un groupe avec `hosts: <NOM_GROUPE>`

```ini
# crée un groupe de serveurs
# ce nom est utilisé dans hosts: du playbook et dans group_vars/<NOM_GROUPE>.yml
[<NOM_GROUPE>]

# un serveur :
#   <NOM_HOTE>                    surnom affiché dans les logs
#   ansible_host                  vraie adresse (IP ou DNS)
#   ansible_user                  utilisateur SSH
#   ansible_ssh_private_key_file  clé privée pour la connexion
<NOM_HOTE> ansible_host=<IP_SERVEUR> ansible_user=<SSH_USER> ansible_ssh_private_key_file=<CHEMIN_CLE_PRIVEE>

# un 2e serveur : une ligne de plus, le playbook s'exécutera sur les deux
# <NOM_HOTE_2> ansible_host=<IP_SERVEUR_2> ansible_user=<SSH_USER> ansible_ssh_private_key_file=<CHEMIN_CLE_PRIVEE>

# test en local, sans SSH (exécute directement sur ta machine)
# local ansible_host=localhost ansible_connection=local

# variables communes à tous les serveurs du groupe
[<NOM_GROUPE>:vars]

# chemin de Python sur le serveur (Ansible en a besoin pour ses modules)
ansible_python_interpreter=/usr/bin/python3

# port SSH si ce n'est pas 22
# ansible_port=<PORT_SSH>
```

## Même inventaire en YAML (inventory.yml)

```yaml
# groupe racine qui contient tout
all:
  # liste des sous-groupes
  children:
    # équivalent de [<NOM_GROUPE>]
    <NOM_GROUPE>:
      # liste des serveurs du groupe
      hosts:
        # un serveur et ses variables
        <NOM_HOTE>:
          ansible_host: <IP_SERVEUR>
          ansible_user: <SSH_USER>
          ansible_ssh_private_key_file: <CHEMIN_CLE_PRIVEE>
```

## Tester

```bash
# se connecte à chaque serveur du groupe, répond "pong" si SSH + Python marchent
ansible <NOM_GROUPE> -m ping

# affiche l'arbre des groupes et serveurs pour vérifier que l'inventaire est bien lu
ansible-inventory --graph
```
