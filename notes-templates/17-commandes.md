# Anti-sèche commandes

## Ansible

```sh
ansible-galaxy collection install -r requirements.yml
ansible <NOM_GROUPE> -m ping                          # test connexion
ansible <NOM_GROUPE> -m setup                         # voir les facts
ansible <NOM_GROUPE> -a "uptime"                      # commande ad-hoc
ansible-playbook playbook.yml --syntax-check
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --tags <TAG> --ask-vault-pass
ansible-playbook playbook.yml --check --diff          # dry-run
ansible-playbook playbook.yml -v / -vvv               # verbose
ansible-playbook playbook.yml --list-tasks
ansible-playbook playbook.yml -e "<VAR>=<VALEUR>"
ansible-playbook teardown.yml --ask-vault-pass -e full_wipe=true
```

## Vault

```sh
ansible-vault create|edit|view|encrypt|decrypt|rekey group_vars/<NOM_GROUPE>.yml
```

## Docker (sur le serveur, dans <PROJECT_DIR>)

```sh
cd <PROJECT_DIR>
docker compose ps
docker compose logs -f <NOM_SERVICE>
docker compose exec <NOM_SERVICE> sh
docker compose restart <NOM_SERVICE>
docker compose up -d --force-recreate
docker compose down            # garde les volumes
docker compose down -v         # SUPPRIME les volumes
docker volume ls
docker network ls
docker image ls
```

## Vérifs serveur

```sh
sudo ufw status verbose
swapon --show && free -h
sudo ss -tlnp                  # ports ouverts
curl -kI https://<IP_SERVEUR>/
sudo reboot                    # puis vérifier que tout redémarre (restart: always)
```

## Lecture d'un run

| Statut | Sens |
|---|---|
| `ok` | déjà dans l'état voulu, rien fait |
| `changed` | modification appliquée |
| `skipping` | condition `when` fausse |
| `failed` | erreur |
| `unreachable` | SSH impossible |

2e run d'un playbook idempotent → `changed=0`.
