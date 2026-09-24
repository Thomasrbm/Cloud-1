# Aide-mémoire des commandes

## Ansible

```bash
ansible-galaxy collection install -r requirements.yml
```

- Installe les collections nécessaires.

```bash
ansible <NOM_GROUPE> -m ping
```

- Teste la connexion SSH à tous les serveurs du groupe.

```bash
ansible <NOM_GROUPE> -m setup
```

- Affiche toutes les infos détectées sur le serveur (facts).

```bash
ansible <NOM_GROUPE> -a "uptime"
```

- Lance une commande ponctuelle sur les serveurs.

```bash
ansible-playbook playbook.yml --syntax-check
```

- Vérifie la syntaxe sans rien lancer.

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

- Déploiement complet.

```bash
ansible-playbook playbook.yml --tags <TAG> --ask-vault-pass
```

- Déploie un seul rôle.

```bash
ansible-playbook playbook.yml --check --diff
```

- Simulation, montre les différences.

```bash
ansible-playbook playbook.yml -vvv
```

- Mode très détaillé pour débugger.

```bash
ansible-playbook playbook.yml --list-tasks
```

- Liste les tâches sans les lancer.

```bash
ansible-playbook playbook.yml -e "<VAR>=<VALEUR>"
```

- Force une variable, priorité maximale.

## Vault

```bash
ansible-vault edit group_vars/<NOM_GROUPE>.yml
```

- Modifie les secrets. Aussi : `create`, `view`, `encrypt`, `decrypt`, `rekey`.

## Docker, sur le serveur

```bash
cd <PROJECT_DIR>
```

- Se placer dans le projet pour que compose trouve le `.env`.

```bash
docker compose ps
```

- État de tous les conteneurs.

```bash
docker compose logs -f <NOM_SERVICE>
```

- Logs d'un service en direct.

```bash
docker compose exec <NOM_SERVICE> sh
```

- Ouvre un terminal dans le conteneur.

```bash
docker compose restart <NOM_SERVICE>
```

- Redémarre un service.

```bash
docker compose up -d --force-recreate
```

- Recrée tous les conteneurs.

```bash
docker compose down
```

- Arrête tout, garde les données.

```bash
docker compose down -v
```

- Arrête tout et SUPPRIME les données.

```bash
docker volume ls
```

- Liste les volumes. Aussi : `docker network ls`, `docker image ls`.

## Vérifications serveur

```bash
sudo ufw status verbose
```

- Pare-feu et ports ouverts.

```bash
free -h
```

- RAM et swap.

```bash
sudo ss -tlnp
```

- Ports en écoute et programmes associés.

```bash
curl -kI https://<IP_SERVEUR>/
```

- Teste le site en HTTPS.

```bash
sudo reboot
```

- Redémarre. Après, tout doit revenir tout seul grâce à `restart: always`.

## Lire le résultat d'un playbook

- `ok` : déjà dans le bon état, rien à faire
- `changed` : une modification a été appliquée
- `skipping` : tâche sautée car la condition `when` est fausse
- `failed` : erreur
- `unreachable` : connexion SSH impossible
- Deuxième lancement d'un playbook bien fait : `changed=0`
