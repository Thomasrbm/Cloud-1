# inventory.ini

```ini
[<NOM_GROUPE>]
<NOM_HOTE>  ansible_host=<IP_SERVEUR>   ansible_user=<SSH_USER> ansible_ssh_private_key_file=<CHEMIN_CLE_PRIVEE>
# <NOM_HOTE2> ansible_host=<IP_SERVEUR_2> ansible_user=<SSH_USER> ansible_ssh_private_key_file=<CHEMIN_CLE_PRIVEE>

# Test en local (sans SSH)
# local ansible_host=localhost ansible_connection=local

# Variables communes à tout le groupe
[<NOM_GROUPE>:vars]
ansible_python_interpreter=/usr/bin/python3
# ansible_port=<PORT_SSH>
```

## Variables d'hôte utiles

| Variable | Rôle |
|---|---|
| `ansible_host` | IP / DNS réel |
| `ansible_user` | utilisateur SSH |
| `ansible_ssh_private_key_file` | clé privée |
| `ansible_port` | port SSH (défaut 22) |
| `ansible_connection` | `ssh` (défaut) / `local` |
| `ansible_python_interpreter` | chemin python sur la cible |

## Version YAML équivalente (`inventory.yml`)

```yaml
all:
  children:
    <NOM_GROUPE>:
      hosts:
        <NOM_HOTE>:
          ansible_host: <IP_SERVEUR>
          ansible_user: <SSH_USER>
          ansible_ssh_private_key_file: <CHEMIN_CLE_PRIVEE>
```

## Tester

```sh
ansible <NOM_GROUPE> -m ping
ansible-inventory --graph
```
