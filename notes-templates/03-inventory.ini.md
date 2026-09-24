# inventory.ini

## À quoi ça sert

C'est la liste des serveurs qu'Ansible va configurer, rangés par groupes. Le playbook cible un groupe avec `hosts: <NOM_GROUPE>`.

## Le fichier

```ini
[<NOM_GROUPE>]
<NOM_HOTE> ansible_host=<IP_SERVEUR> ansible_user=<SSH_USER> ansible_ssh_private_key_file=<CHEMIN_CLE_PRIVEE>

[<NOM_GROUPE>:vars]
ansible_python_interpreter=/usr/bin/python3
```

## Ligne par ligne

- `[<NOM_GROUPE>]` : crée un groupe de serveurs. Le nom entre crochets est celui que tu mets dans `hosts:` du playbook et dans `group_vars/<NOM_GROUPE>.yml`
- `<NOM_HOTE>` : surnom du serveur, affiché dans les logs d'Ansible
- `ansible_host=<IP_SERVEUR>` : vraie adresse du serveur (IP ou nom DNS)
- `ansible_user=<SSH_USER>` : utilisateur pour se connecter en SSH
- `ansible_ssh_private_key_file=<CHEMIN_CLE_PRIVEE>` : clé privée utilisée pour la connexion
- `[<NOM_GROUPE>:vars]` : section des variables communes à tous les serveurs du groupe
- `ansible_python_interpreter=/usr/bin/python3` : chemin de Python sur le serveur. Ansible en a besoin pour exécuter ses modules

## Ajouter un deuxième serveur

```ini
<NOM_HOTE_2> ansible_host=<IP_SERVEUR_2> ansible_user=<SSH_USER> ansible_ssh_private_key_file=<CHEMIN_CLE_PRIVEE>
```

- Une ligne de plus sous `[<NOM_GROUPE>]`. Le playbook s'exécutera sur les deux.

## Tester en local, sans SSH

```ini
local ansible_host=localhost ansible_connection=local
```

- `ansible_connection=local` : exécute directement sur ta machine, sans passer par SSH.

## Autres variables utiles

- `ansible_port=<PORT_SSH>` : port SSH si ce n'est pas 22
- `ansible_connection=ssh` : type de connexion (ssh par défaut, ou local)
- `ansible_become_password=<MDP>` : mot de passe sudo (à mettre dans le vault)

## Même inventaire en YAML (inventory.yml)

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

- `all:` : groupe racine qui contient tout
- `children:` : liste des sous-groupes
- `<NOM_GROUPE>:` : équivalent de `[<NOM_GROUPE>]`
- `hosts:` : liste des serveurs du groupe
- `<NOM_HOTE>:` : un serveur, avec ses variables en dessous
- `ansible_host`, `ansible_user`, `ansible_ssh_private_key_file` : mêmes variables que dans le `.ini`

## Tester l'inventaire

```bash
ansible <NOM_GROUPE> -m ping
```

- Se connecte à chaque serveur du groupe et répond `pong` si SSH et Python fonctionnent.

```bash
ansible-inventory --graph
```

- Affiche l'arbre des groupes et des serveurs, pour vérifier que l'inventaire est bien lu.
