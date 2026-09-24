# Aide-mémoire des commandes

## Ansible

```bash
# installe les collections nécessaires
ansible-galaxy collection install -r requirements.yml

# teste la connexion SSH à tous les serveurs du groupe
ansible <NOM_GROUPE> -m ping

# affiche toutes les infos détectées sur le serveur (facts)
ansible <NOM_GROUPE> -m setup

# lance une commande ponctuelle sur les serveurs
ansible <NOM_GROUPE> -a "uptime"

# vérifie la syntaxe sans rien lancer
ansible-playbook playbook.yml --syntax-check

# déploiement complet
ansible-playbook playbook.yml --ask-vault-pass

# un seul rôle
ansible-playbook playbook.yml --tags <TAG> --ask-vault-pass

# simulation, montre les différences
ansible-playbook playbook.yml --check --diff --ask-vault-pass

# mode très détaillé pour débugger
ansible-playbook playbook.yml -vvv --ask-vault-pass

# liste les tâches sans les lancer
ansible-playbook playbook.yml --list-tasks

# force une variable (priorité maximale)
ansible-playbook playbook.yml -e "<VAR>=<VALEUR>" --ask-vault-pass

# modifie les secrets (aussi : create, view, encrypt, decrypt, rekey)
ansible-vault edit group_vars/<NOM_GROUPE>.yml
```

## Docker (sur le serveur)

```bash
# se placer dans le projet pour que compose trouve le .env
cd <PROJECT_DIR>

# état de tous les conteneurs
docker compose ps

# logs d'un service en direct
docker compose logs -f <NOM_SERVICE>

# ouvre un terminal dans le conteneur
docker compose exec <NOM_SERVICE> sh

# redémarre un service
docker compose restart <NOM_SERVICE>

# recrée tous les conteneurs
docker compose up -d --force-recreate

# arrête tout, garde les données
docker compose down

# arrête tout et SUPPRIME les données
docker compose down -v

# liste volumes / réseaux / images
docker volume ls
docker network ls
docker image ls
```

## Vérifications serveur

```bash
# pare-feu et ports ouverts
sudo ufw status verbose

# RAM et swap
free -h

# ports en écoute et programmes associés
sudo ss -tlnp

# teste le site en HTTPS
curl -kI https://<IP_SERVEUR>/

# redémarre : tout doit revenir seul grâce à restart: always
sudo reboot
```

## Lire le résultat d'un playbook

- `ok` : déjà dans le bon état, rien à faire
- `changed` : modification appliquée
- `skipping` : condition `when` fausse
- `failed` : erreur
- `unreachable` : SSH impossible
- 2e lancement d'un playbook bien fait : `changed=0`
