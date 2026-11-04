# RÉSUMÉ COMPLET — Cloud-1

> **Mode d'emploi**
> - Ce fichier sert de **briefing à coller dans une conversation avec Claude** (texte ou vocal) pour revoir tout le projet de A à Z.
> - Copie **tout le fichier** (de ce titre jusqu'à la fin) dans une nouvelle conversation, avec le prompt de la section 0 en premier.
> - Tout le reste du fichier est le contexte : architecture, arborescence, rôles, secrets, idempotence, définitions, debug, correction.

---

## 0. Prompt à coller en premier (pour la conversation vocale)

```text
Tu es mon binôme de révision pour mon projet 42 "Cloud-1". Je vais avoir une
conversation VOCALE avec toi : réponds court, en phrases parlées, sans tableaux
ni listes longues, une idée à la fois. Pas de blocs de code sauf si je les demande.

Ci-dessous tu as le résumé complet du projet : architecture, tous les fichiers,
chaque rôle Ansible, le vault, l'idempotence, les handlers, la sécurité, le
debug, les définitions et la grille de correction.

Ce que j'attends de toi :
1. M'expliquer chaque partie quand je te le demande, du "pourquoi" au "comment".
2. Me poser des questions de soutenance comme un correcteur, une par une,
   et corriger mes réponses.
3. Me faire remarquer quand je confonds deux notions (ex : ok/changed,
   Ansible vs Docker, {{ }} vs ${ }, volume vs bind mount).
4. Ne pas inventer : si un détail n'est pas dans le résumé, dis-le.

Commence par me demander par quelle partie je veux commencer.
```

---

## 1. Le projet en 30 secondes

- **Sujet (42)** : déployer automatiquement un site **WordPress** complet sur un **serveur cloud vierge**, avec une seule commande.
- **Outils**
  - **Ansible** → configure le serveur à distance via SSH (installe, copie, lance).
  - **Docker + Docker Compose** → fait tourner chaque service dans son conteneur.
  - **AWS EC2** → la machine : `t3.micro`, Ubuntu 22.04, région `eu-north-1` (Stockholm).
  - **Ansible Vault** → chiffre les mots de passe (AES-256) pour pouvoir les versionner dans git.
- **La commande unique**
  ```sh
  ansible-playbook playbook.yml --ask-vault-pass
  ```
- **Résultat** : en partant d'un Ubuntu nu →
  - clés SSH autorisées, swap 2 Go, Docker installé, pare-feu configuré ;
  - 4 conteneurs : **MySQL**, **WordPress (php-fpm)**, **phpMyAdmin**, **nginx** ;
  - site installé automatiquement (pas d'assistant d'installation) ;
  - HTTPS (certificat auto-signé), HTTP redirigé en 301 vers HTTPS.
- **Idée clé** : `git clone` + le mot de passe du vault suffisent pour déployer depuis n'importe quelle machine.

---

## 2. Arborescence complète (annotée)

```
Cloud-1/
├── ansible.cfg                  # config d'Ansible : où est l'inventaire, quelle clé SSH, vitesse SSH
├── inventory.ini                # LA CIBLE : groupe [webservers] → server1 = IP de l'EC2, user ubuntu
├── playbook.yml                 # LE POINT D'ENTRÉE : liste les 9 rôles dans l'ordre, avec leurs tags
├── teardown.yml                 # l'inverse : remet le serveur à zéro (standard ou full_wipe)
├── requirements.yml             # collections Ansible à installer : community.general (ufw), ansible.posix
├── .gitignore                   # bloque *.pem, *.key, vault_pass.txt, mdp.txt…
├── README.md                    # doc officielle en anglais (vitrine du projet)
├── run.log                      # sortie -vvv d'un vrai run (⚠ contient un mot de passe, voir §14)
│
├── group_vars/                  # variables chargées AUTOMATIQUEMENT selon le nom du groupe
│   ├── all.yml                  # en clair : project_dir, ports, swap, liste des compose, infos WP
│   ├── webservers.yml           # CHIFFRÉ (vault) : les 4 mots de passe
│   └── webservers.yml.example   # modèle en clair des clés attendues (valeurs bidon)
│
├── roles/                       # 1 rôle = 1 brique ; chaque rôle a tasks/ (+ templates/, handlers/, files/)
│   ├── ssh_access/              # 0. clés publiques + accès root par clé
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml    #    "Restart sshd" (reload, ne coupe pas la session)
│   │   └── files/               #    portable.pub + README (1 fichier .pub par machine)
│   ├── swap/tasks/main.yml      # 1. fichier d'échange 2 Go, swappiness 10
│   ├── docker/tasks/main.yml    # 2. dépôt apt officiel Docker + Engine + plugin compose
│   ├── ufw/tasks/main.yml       # 3. pare-feu : deny entrant, allow 22/80/443
│   ├── stack/                   # 4. socle : /opt/wordpress, .env, réseau, volumes
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml    #    "Recreate stack" (up -d --force-recreate)
│   │   └── templates/
│   │       ├── env.j2           #    → /opt/wordpress/.env (0600)
│   │       └── docker-compose.yml.j2  # → réseau wp_network + volumes mysql_data, wp_data
│   ├── db/                      # 5. MySQL 8.0
│   │   ├── tasks/main.yml
│   │   └── templates/compose.db.yml.j2
│   ├── wordpress/               # 6. WordPress php-fpm + wp-cli
│   │   ├── tasks/main.yml
│   │   └── templates/compose.wordpress.yml.j2
│   ├── phpmyadmin/              # 7. phpMyAdmin
│   │   ├── tasks/main.yml
│   │   └── templates/compose.phpmyadmin.yml.j2
│   └── proxy/                   # 8. nginx + TLS (le SEUL exposé)
│       ├── tasks/main.yml
│       ├── handlers/main.yml    #    "Restart nginx"
│       └── templates/
│           ├── nginx.conf.j2
│           └── compose.proxy.yml.j2
│
├── Correc/                      # fiches perso pour la soutenance
│   ├── EXPLICATION.txt          # déroulé complet de la correction, point par point, avec commandes
│   ├── definitions.txt          # IaC, idempotence, étapes de provisioning
│   ├── debug.txt                # verbosité -v/-vvv, grep des erreurs, sens des statuts
│   ├── error.yml                # playbook de démo qui provoque des erreurs exprès
│   └── le vault.txt             # créer / chiffrer / éditer le vault
│
└── txt/                         # notes détaillées (français)
    ├── EXPLICATION_PROJET.txt   # ancien README en français
    ├── CORREC.txt               # aide-mémoire des commandes de soutenance
    ├── CONTAINERS.txt           # volumes, images, cache, orchestration, réseau
    ├── exec_playbook.txt        # lire un PLAY RECAP : les 7 compteurs + codes retour
    ├── NOTIFS.md                # notify / handlers en détail
    ├── SECRETS.txt / vault.txt  # chemin des secrets, génération des mots de passe
    ├── AWS.md                   # créer l'EC2, Security Group, Elastic IP, coûts, multi-machines, root
    ├── acces.txt                # les 3 URLs + users (mots de passe → vault)
    └── SOURCES.md               # liens vers la doc officielle de chaque brique
```

**Sur le serveur, après déploiement**

```
/opt/wordpress/                      # project_dir (nom du dossier = nom du projet compose "wordpress")
├── .env                             # 0600 root : COMPOSE_FILE + 4 variables MySQL
├── docker-compose.yml               # socle (réseau + volumes)
├── compose.db.yml                   # mysql
├── compose.wordpress.yml            # wordpress + wpcli
├── compose.phpmyadmin.yml           # phpmyadmin
├── compose.proxy.yml                # nginx
├── nginx/nginx.conf                 # bind mount en lecture seule dans nginx
└── ssl/cert.pem + key.pem           # certificat auto-signé
/var/lib/docker/volumes/             # drwx--x--- root : wordpress_mysql_data, wordpress_wp_data
/swapfile                            # 2 Go, 0600
```

- Noms générés par Compose, préfixés par le nom du dossier (`wordpress`) :
  - conteneurs : `wordpress-mysql-1`, `wordpress-wordpress-1`, `wordpress-phpmyadmin-1`, `wordpress-nginx-1`
  - réseau : `wordpress_wp_network`
  - volumes : `wordpress_mysql_data`, `wordpress_wp_data`

---

## 3. Ce qui se passe quand on lance la commande (flux complet)

1. **`ansible-playbook playbook.yml --ask-vault-pass`** sur **ma machine** (pas sur le serveur).
2. Ansible lit **`ansible.cfg`** → trouve `inventory = inventory.ini`, la clé SSH, `pipelining`, `ControlPersist`.
3. Il lit **`inventory.ini`** → groupe `webservers` = `server1` (IP, user `ubuntu`, clé `.pem`).
4. Il demande le **mot de passe du vault**.
5. Il charge **`group_vars/all.yml`** (tout le monde) et **`group_vars/webservers.yml`** (groupe webservers), qu'il **déchiffre en RAM**.
6. **Gathering Facts** : il se connecte en SSH et récupère les infos du serveur (OS, archi, RAM, swap…) → variables `ansible_*`.
7. `become: true` → chaque tâche passe en **root via sudo** (sudo sans mot de passe sur l'AMI Ubuntu).
8. Il exécute les **9 rôles dans l'ordre** (section 5).
9. À la **fin du play**, il exécute les **handlers** notifiés (Recreate stack, Restart nginx, Restart sshd).
10. Il affiche le **PLAY RECAP** (`ok / changed / failed / …`).

**Chemin d'une requête web**

```
Navigateur → Security Group AWS (22/80/443) → UFW (22/80/443) → nginx :443 (TLS)
   ├── *.php           → FastCGI → wordpress:9000 (php-fpm) → mysql:3306
   ├── /phpmyadmin/    → proxy_pass → phpmyadmin:80        → mysql:3306
   └── fichiers statiques (css, images) → servis direct par nginx depuis wp_data
HTTP :80 → 301 → HTTPS
```

---

## 4. Architecture (schéma)

```
                         Internet
                            │
                  AWS Security Group  (22 / 80 / 443)
                            │
                  UFW sur l'instance (deny par défaut)
                            │
      ┌─────────────────────┼──────────── EC2 t3.micro · Ubuntu 22.04 ─┐
      │                     ▼                                          │
      │   ┌──────────────────────────────┐                             │
      │   │  nginx:alpine  :80  :443     │  TLS auto-signé, 80 → 443   │
      │   └──────┬───────────────┬───────┘                             │
      │     *.php│ FastCGI :9000 │ /phpmyadmin/  proxy_pass :80        │
      │          ▼               ▼                                     │
      │   ┌─────────────┐  ┌─────────────┐                             │
      │   │ wordpress   │  │ phpmyadmin  │        bridge : wp_network  │
      │   │ php8.1-fpm  │  └──────┬──────┘                             │
      │   └──────┬──────┘         │                                    │
      │          └───────┬────────┘                                    │
      │                  ▼  :3306 (jamais publié)                      │
      │           ┌─────────────┐                                      │
      │           │  mysql:8.0  │                                      │
      │           └─────────────┘                                      │
      │   volumes : wp_data (partagé nginx + wordpress) · mysql_data   │
      └────────────────────────────────────────────────────────────────┘
```

- **1 processus = 1 conteneur** (base, runtime PHP, proxy web séparés).
- **Un seul réseau bridge** `wp_network` : les conteneurs se parlent par leur **nom de service** (DNS interne Docker) → `mysql`, `wordpress`, `phpmyadmin`.
- **Seul nginx publie des ports**. Les autres n'ont aucune section `ports:`.
- **Uniquement des images officielles**, aucun `Dockerfile`, aucun `build:`.

| Image | Taille ~ | Pourquoi ce choix |
|---|---|---|
| `nginx:alpine` | 50 Mo | variante Alpine, la plus légère |
| `wordpress:cli` | 80 Mo | éphémère (`--rm`), sert juste à installer le site |
| `wordpress:php8.1-fpm` | 500 Mo | PHP seul, sans Apache (nginx fait déjà le serveur web) |
| `phpmyadmin:latest` | 570 Mo | interface admin MySQL |
| `mysql:8.0` | 600 Mo | pas de variante Alpine officielle |

---

## 5. Les rôles, un par un

> Principe général : chaque rôle a un `tasks/main.yml` = liste de tâches. Chaque tâche appelle un **module** Ansible (`apt`, `file`, `template`, `command`…). Chaque rôle a un **tag** → rejouable seul avec `--tags`.

### Rôle 0 — `ssh_access` (tag `ssh`)
- **But**
  - autoriser plusieurs machines (fixe, portable, poste 42) **sans partager la clé privée** ;
  - ouvrir **l'accès root par clé** (exigé à la soutenance : « The student must connect as root »).
- **Comment**
  - `authorized_key` + `with_fileglob: "*.pub"` → ajoute chaque `files/*.pub` à `~/.ssh/authorized_keys` de `ubuntu`, puis de `root`.
  - `replace` avec une regex → retire le `command="echo 'Please login as the user ubuntu'"` que les AMI cloud mettent devant la clé root (il tue la session).
  - `lineinfile` → `PermitRootLogin prohibit-password` (clé oui, mot de passe jamais), avec **`validate: sshd -t -f %s`** → si la config est cassée, Ansible refuse de l'écrire (sinon on se verrouille dehors).
  - `find` + `replace` dans `/etc/ssh/sshd_config.d/*.conf` → neutralise les fichiers inclus qui forceraient `PermitRootLogin no` (ils sont prioritaires sur le fichier principal).
  - `notify: Restart sshd` → handler `service ssh state=reloaded` (recharge sans couper les sessions).
- **Désactivable** : `allow_root_ssh: false`.
- **Piège** : le tout premier run se fait forcément en `ubuntu` (root encore bloqué).

### Rôle 1 — `swap` (tags `swap`, `system`)
- **Pourquoi** : t3.micro = 1 Go RAM, aucun swap fourni → un `apt install` à côté de MySQL suffit pour que l'**OOM killer** tue un conteneur.
- **Condition** (`when:` sur tout le `block:`) : `swap_enabled` **et** `ansible_swaptotal_mb == 0` (fact récupéré au Gathering Facts).
- **Étapes**
  - `fallocate -l 2048M /swapfile` avec `creates:` → réserve la place d'un coup (plus rapide que `dd`).
  - `chmod 0600` root → obligatoire, sinon la mémoire swappée serait lisible par d'autres users.
  - `mkswap` puis `swapon` **seulement si** le fichier vient d'être créé (`when: swap_allocated.changed`) → reformater un swap actif corromprait les pages.
  - `mount` → ligne dans `/etc/fstab` (survit au reboot).
  - `sysctl vm.swappiness=10` → le noyau ne swappe qu'en dernier recours (défaut 60).
- **Run suivant** : swap déjà là → toutes les tâches **skipped**.

### Rôle 2 — `docker` (tag `docker`)
- Traduction Ansible de la doc officielle « Install Docker Engine on Ubuntu ».
- **Étapes**
  - `apt` : prérequis (`ca-certificates`, `curl`, `gnupg`, `lsb-release`, `apt-transport-https`) + `update_cache`.
  - `file` : crée `/etc/apt/keyrings`.
  - `get_url` : télécharge la **clé GPG** Docker → `/etc/apt/keyrings/docker.asc` (prouve que les paquets viennent bien de Docker).
  - `apt_repository` : ajoute le dépôt, avec l'archi (`amd64`/`arm64` selon `ansible_architecture`) et la version d'Ubuntu (`ansible_distribution_release` → `jammy`).
  - `apt` : `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` (Compose V2 → `docker compose`, avec un espace).
  - `service` : `started` + `enabled` (redémarre au boot).

### Rôle 3 — `ufw` (tags `ufw`, `security`)
- `apt install ufw`.
- `community.general.ufw` : **deny incoming**, **allow outgoing**.
- `loop` sur `22`, `80`, `443` en TCP → les 3 exceptions.
- `state: enabled`.
- **22 indispensable** : Ansible ne parle **que** par SSH.
- **Ordre** : on autorise 22 **avant** d'activer → on ne se coupe pas soi-même.

### Rôle 4 — `stack` (tag `stack`) — le socle
- **Aucun conteneur applicatif** ici.
- `file` : crée `/opt/wordpress` (0755).
- `template env.j2` → **`.env` en 0600** (root uniquement), contient :
  - `COMPOSE_FILE=docker-compose.yml:compose.db.yml:compose.wordpress.yml:compose.phpmyadmin.yml:compose.proxy.yml`
  - `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` (venus du vault).
- `template docker-compose.yml.j2` → déclare seulement `networks: wp_network (bridge)` et `volumes: mysql_data, wp_data`.
- Les deux templates font `notify: Recreate stack`.
- **Handler `Recreate stack`** : `docker compose up -d --force-recreate --remove-orphans`.
  - Pourquoi `--force-recreate` : un conteneur lit ses variables d'env **une seule fois, à sa création**. Un simple `up -d` ne relirait pas un nouveau mot de passe.
  - `--remove-orphans` : supprime les conteneurs de services qui n'existent plus.

### Rôle 5 — `db` (tag `db`)
- `template compose.db.yml.j2` → service `mysql` :
  - `image: mysql:8.0`, `restart: always`
  - variables `${MYSQL_…}` lues dans le `.env`
  - volume `mysql_data:/var/lib/mysql`, réseau `wp_network`, **aucun `ports:`**.
- `command: docker compose -f docker-compose.yml -f compose.db.yml up -d mysql`
  - `register: db_up` + **`changed_when`** : `changed` seulement si la sortie contient `Started`, `Created` ou `Recreated` (Docker écrit sa progression sur **stderr**).
- **Attente active** : `mysqladmin ping` dans le conteneur, `until: rc == 0`, `retries: 30`, `delay: 5` (jusqu'à 150 s) → MySQL met 10-30 s à s'initialiser.
  - `failed_when: false` sur l'attente, puis une tâche `fail` avec **message clair** si ça n'a jamais répondu.
- **Pourquoi `-f` explicites** : au 1er déploiement, `compose.proxy.yml` etc. n'existent pas encore → si Compose lisait `COMPOSE_FILE` du `.env`, il planterait sur des fichiers absents.

### Rôle 6 — `wordpress` (tags `wordpress`, `wp`)
- `template compose.wordpress.yml.j2` → 2 services :
  - **`wordpress`** : `wordpress:php8.1-fpm`, `WORDPRESS_DB_HOST: mysql`, volume `wp_data:/var/www/html`.
  - **`wpcli`** : `wordpress:cli`, `profiles: [tools]` → **ne démarre jamais** avec un `up` normal ; `user: "33:33"` (= `www-data`, le même user que php-fpm → bons propriétaires de fichiers).
- `up -d wordpress` + `changed_when` (même logique que db).
- **Attente** : `test -f /var/www/html/wp-includes/version.php` en boucle → l'image copie les fichiers WordPress dans le volume au démarrage, et Compose n'attend pas.
- **Installation automatique par wp-cli**
  - `docker compose … --profile tools run --rm -T wpcli wp core is-installed` → `rc 0` = déjà installé.
    - `run` = conteneur **neuf** (≠ `exec` qui entre dans un existant), `--rm` = supprimé après, `-T` = pas de terminal.
    - même réseau que mysql + même volume que wordpress → il voit la base et les fichiers.
  - `wp core install --url --title --admin_user --admin_password --admin_email --skip-email` **seulement si** `is-installed` a échoué (`when: rc != 0`).
- **Résultat** : site live dès la fin du playbook, sans le formulaire web.

### Rôle 7 — `phpmyadmin` (tags `phpmyadmin`, `pma`)
- Service `phpmyadmin:latest`, `PMA_HOST: mysql`, `PMA_PORT: 3306`.
- `PMA_ABSOLUTE_URI: https://<IP>/phpmyadmin/` → pour que les liens générés marchent derrière nginx sous un sous-chemin (le `{% if https_port != 443 %}` ajoute le port si non standard).
- Aucun port publié : accessible **uniquement via nginx**.

### Rôle 8 — `proxy` (tags `proxy`, `nginx`)
- Crée `nginx/` et `ssl/`.
- **Certificat auto-signé** : `openssl req -x509 -nodes -days 365 -newkey rsa:2048 …` avec **`creates: ssl/cert.pem`** → généré une seule fois.
- `template nginx.conf.j2` → `notify: Restart nginx`.
- `template compose.proxy.yml.j2` → service `nginx:alpine` :
  - **seul** à avoir `ports: 80:80, 443:443` ;
  - `nginx.conf` et `ssl/` montés en **`:ro`** (lecture seule) ;
  - `wp_data:/var/www/html` → nginx sert le statique directement, et a le même chemin que php-fpm pour `SCRIPT_FILENAME`.
- `docker compose up -d nginx` (ici sans `-f` : tous les fichiers existent → `COMPOSE_FILE` du `.env` suffit).
- **Convergence finale** : `docker compose up -d --remove-orphans` sur toute la stack.
- **Pourquoi en dernier** : nginx plante au démarrage s'il ne peut pas résoudre `wordpress` ou `phpmyadmin` → ils doivent exister avant.

**`nginx.conf.j2` en détail**

| Bloc | Rôle |
|---|---|
| `server { listen 80 … return 301 https://$host$request_uri; }` | tout HTTP → HTTPS (redirection définitive) |
| `listen 443 ssl default_server; server_name _;` | répond sur l'IP, quel que soit le nom demandé |
| `location = /phpmyadmin { return 301 /phpmyadmin/; }` | ajoute le `/` final manquant |
| `location ^~ /phpmyadmin/ { proxy_pass http://phpmyadmin:80/; … }` | reverse-proxy HTTP vers phpMyAdmin + en-têtes `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto` |
| `location / { try_files $uri $uri/ /index.php?$args; }` | fichier réel sinon → WordPress (permaliens) |
| `location ~ \.php$ { fastcgi_pass wordpress:9000; … }` | exécute le PHP via FastCGI dans php-fpm |
| `fastcgi_param HTTPS on;` | le TLS s'arrête à nginx ; sans ça PHP croit être en HTTP → **boucle de redirection** |
| `location = /preuve` (commenté) | page de démo « Déployé par Ansible » pour prouver un déploiement sur un 2e serveur |

---

## 6. Un fichier compose par composant

- **Problème** : un seul gros `docker-compose.yml` → impossible de déployer une brique seule.
- **Solution** : chaque rôle dépose **son** fichier, Docker les **fusionne** dans l'ordre de `COMPOSE_FILE` (écrit dans le `.env`, séparateur `:`).

| Fichier | Rôle propriétaire | Contenu |
|---|---|---|
| `docker-compose.yml` | stack | réseau + volumes |
| `compose.db.yml` | db | mysql |
| `compose.wordpress.yml` | wordpress | wordpress + wpcli |
| `compose.phpmyadmin.yml` | phpmyadmin | phpmyadmin |
| `compose.proxy.yml` | proxy | nginx |

- **Avantages**
  - `cd /opt/wordpress && docker compose ps` voit **toute** la stack ;
  - `ansible-playbook playbook.yml --tags phpmyadmin --ask-vault-pass` redéploie **une seule** brique.
- La liste vient de `compose_files` dans `group_vars/all.yml`, transformée par le filtre Jinja `join(':')`.

---

## 7. Secrets — Ansible Vault

- **Fichier** : `group_vars/webservers.yml`, chiffré **AES-256** (clé dérivée du mot de passe par **PBKDF2**), commence par `$ANSIBLE_VAULT;1.1;AES256`.
- **Contenu** : `mysql_root_password`, `mysql_database`, `mysql_user`, `mysql_password`, `wp_admin_password` (voir `.example`).
- **Pourquoi il est dans git** : c'est tout l'intérêt du vault → dépôt autonome. Le sujet interdit les secrets **en clair** ; un blob AES-256 n'est pas en clair.
- **Ce qui n'est jamais dans git** : le **mot de passe du vault** lui-même.
- **Le chemin d'un secret**

```
group_vars/webservers.yml (chiffré, git)
   │  --ask-vault-pass → déchiffré en RAM sur MA machine
   ▼
roles/stack/templates/env.j2          {{ mysql_password }}   ← Jinja / Ansible, au déploiement
   ▼
/opt/wordpress/.env (0600, root)      ${MYSQL_PASSWORD}      ← Docker Compose, au lancement
   ▼
variables d'environnement des conteneurs
```

- **`{{ }}` vs `${ }`** (question piège)
  - `{{ var }}` = **Jinja2**, remplacé par **Ansible** sur ma machine en générant le fichier.
  - `${VAR}` = **interpolation Compose**, remplacé par **Docker** sur le serveur à partir du `.env`.
- **Commandes**
  ```sh
  openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24; echo   # générer un mot de passe
  cp group_vars/webservers.yml.example group_vars/webservers.yml
  ansible-vault encrypt group_vars/webservers.yml
  ansible-vault view    group_vars/webservers.yml
  ansible-vault edit    group_vars/webservers.yml     # se re-chiffre tout seul
  ansible-vault rekey   group_vars/webservers.yml     # changer le mot de passe du vault
  head -1 group_vars/webservers.yml                    # vérifier : $ANSIBLE_VAULT;1.1;AES256
  ```
- **Mot de passe du vault perdu = fichier perdu.**
- **Pourquoi `--ask-vault-pass` même pour `teardown.yml` ou une commande ad-hoc** : cibler le groupe `webservers` fait charger `group_vars/webservers.yml`, qui est chiffré → sans mot de passe Ansible refuse de démarrer.

---

## 8. Idempotence et handlers

### Idempotence
- **Définition** : rejouer le playbook sur une machine déjà bonne **ne change rien** → 2e run = `changed=0`.
- Les modules (`apt`, `file`, `template`…) sont idempotents nativement : ils comparent l'état voulu et l'état réel.
- **`command` / `shell` ne le sont pas** (Ansible les compte toujours `changed`) → il faut les encadrer :

| Mécanisme | Où | Effet |
|---|---|---|
| `creates:` | certificat TLS, fichier swap | ne relance pas la commande si le fichier existe |
| `changed_when:` sur stderr Docker | tous les `docker compose up` | `changed` seulement si `Created/Started/Recreated` |
| `changed_when: false` | pings, tests, lectures | jamais `changed` |
| `wp core is-installed` + `when:` | wordpress | n'installe qu'une fois |
| `ansible_swaptotal_mb == 0` | swap | rôle sauté si le swap existe |
| `until:` / `retries:` / `delay:` | MySQL, fichiers WP | attend au lieu de faire la course |
| handlers + `notify` | stack, proxy, ssh_access | redémarre seulement si la config a changé |
| `validate: sshd -t` | ssh_access | refuse une config SSH cassée |

### Handlers
- Une tâche `changed` avec `notify: <nom>` **met en file** le handler du même **nom exact**.
- Le handler s'exécute **une seule fois**, **à la fin du play**, même s'il a été notifié 10 fois.
- **Seul `changed` déclenche un notify** (pas `ok`, pas `skipped`).
- Tout se passe **pendant** `ansible-playbook` : rien ne tourne en fond sur le serveur.

| Qui notifie | Handler | Commande |
|---|---|---|
| `.env`, `docker-compose.yml` | `Recreate stack` | `docker compose up -d --force-recreate --remove-orphans` |
| `nginx.conf` | `Restart nginx` | `docker compose restart nginx` |
| `sshd_config` (+ drop-ins) | `Restart sshd` | `service ssh reloaded` |

- **Piège** : si une tâche échoue avant la fin, les handlers en attente **ne tournent jamais** ; au run suivant le fichier est déjà à jour (`ok`) → plus de notify → conteneurs avec l'ancienne config.
  - Solution : `--force-handlers` (ou `meta: flush_handlers`, non utilisé ici).

---

## 9. Sécurité

- **Deux pare-feu** : Security Group AWS (dehors) + UFW (dedans). Un port doit être ouvert **dans les deux**.
- **MySQL jamais exposé** : pas de `ports:`, joignable seulement sur `wp_network`. Même si UFW tombait, 3306 resterait fermé.
- **HTTP → HTTPS** : le port 80 ne fait que renvoyer un 301.
- **SSH** : clés uniquement, root en `prohibit-password`, une clé par machine (révoquer une machine sans tout changer).
- **Fichiers sensibles** : `.env` en 0600, `/var/lib/docker` en `drwx--x---` (root seulement), swap en 0600.
- **Montages config en `:ro`** dans nginx.
- **`.gitignore`** : `*.pem`, `*.key`, `vault_pass.txt`, `mdp.txt`…
- **Historique git** : d'anciennes versions de `txt/acces.txt` avaient des mots de passe en clair (volontaire pour les correcteurs, serveur de test éteint depuis) — expliqué dans le README.

---

## 10. Teardown (`teardown.yml`)

- **But** : remettre le serveur à zéro pour rejouer la démo devant le correcteur.

| Niveau | Commande | Supprime |
|---|---|---|
| Standard | `ansible-playbook teardown.yml --ask-vault-pass` | conteneurs, images, volumes, `/opt/wordpress` (Docker reste) |
| Total | `… -e full_wipe=true` | + paquets Docker, dépôt apt, clé GPG, `/var/lib/docker`, swap, règles UFW → Ubuntu nu |
| Sans question | `… -e confirm=oui` | saute la confirmation interactive |

- **Garde-fous**
  - `vars_prompt` → il faut taper `oui` ; sinon `assert` → « Annulé ».
  - `assert` sur `project_dir` : défini, commence par `/`, plus de 4 caractères, pas dans `/`, `/root`, `/home`, `/etc`, `/var`, `/usr`, `/opt` → évite un `rm -rf` catastrophique.
  - vérifie si Docker est installé (`docker --version`, `failed_when: false`) → marche même sur un serveur déjà propre (idempotent).
- **Étapes** : `docker compose down -v --remove-orphans --rmi all` → `docker volume rm` explicite (au cas où le `.env` aurait disparu) → suppression du dossier → `docker system prune -af --volumes` → (full) block de désinstallation.
- Ne touche **pas** à l'instance EC2, ni à l'inventaire, ni aux clés SSH.

---

## 11. Définitions (lexique)

| Terme | Définition courte |
|---|---|
| **Infrastructure as Code (IaC)** | décrire son infrastructure (réseau, machines, état voulu) dans des fichiers déclaratifs (YAML) → reproductible, versionné |
| **Idempotence** | si l'état est déjà bon, rejouer ne fait rien |
| **Provisioning** | partir d'une machine vide et finir avec les services qui tournent |
| **Déclaratif** | on décrit l'état voulu (« ufw installé »), pas les étapes |
| **Playbook** | fichier YAML qui associe des hôtes à des rôles/tâches |
| **Play** | un bloc `hosts: … roles: …` dans un playbook |
| **Rôle** | dossier réutilisable (`tasks/`, `handlers/`, `templates/`, `files/`) pour une brique |
| **Tâche / module** | une action ; le module est l'outil (`apt`, `file`, `template`, `command`…) |
| **Inventaire** | liste des serveurs cibles, rangés en groupes (`[webservers]`) |
| **group_vars** | variables chargées automatiquement selon le groupe (`all.yml` = tous) |
| **Facts** | infos collectées sur le serveur au `Gathering Facts` (`ansible_architecture`, `ansible_swaptotal_mb`…) |
| **become** | passer root via sudo |
| **Tag** | étiquette pour ne jouer qu'une partie (`--tags db`) |
| **Template / Jinja2** | fichier `.j2` avec `{{ variables }}`, `{% if %}`, filtres (`| join`, `| int`, `| bool`) |
| **Handler / notify** | tâche différée, déclenchée seulement si une tâche est `changed` |
| **register** | stocke le résultat d'une tâche (`rc`, `stdout`, `stderr`, `changed`) dans une variable |
| **when / until / retries** | condition / boucle d'attente |
| **changed_when / failed_when** | redéfinir quand une tâche compte comme modifiée / échouée |
| **block / rescue** | groupe de tâches / le « catch » en cas d'erreur (pas de rescue ici) |
| **Ansible Vault** | chiffrement AES-256 de fichiers de variables |
| **Pipelining** | envoie le module dans la session SSH au lieu de sftp + exécution → 1 aller-retour au lieu de 4 |
| **ControlPersist** | garde la connexion SSH ouverte 300 s entre deux tâches |
| **Conteneur** | processus isolé à partir d'une image ; éphémère |
| **Image** | modèle en couches, en lecture seule, d'où on crée les conteneurs |
| **Volume nommé** | stockage géré par Docker (`/var/lib/docker/volumes`), survit à la destruction des conteneurs |
| **Bind mount** | un fichier/dossier de l'hôte monté dans le conteneur (ici : config nginx + certificats) |
| **Réseau bridge** | réseau virtuel interne ; DNS par nom de service |
| **Docker Compose** | décrit plusieurs services/réseaux/volumes en YAML et les lance ensemble |
| **Profile Compose** | service qui ne démarre qu'avec `--profile` (ici `wpcli`) |
| **`run` vs `exec`** | `run` crée un conteneur neuf ; `exec` entre dans un conteneur existant |
| **Cache de build** | réutilisation des couches d'image ; règle : dépendances en haut, code en bas (ici aucun build) |
| **Reverse proxy** | serveur en façade qui reçoit tout et redistribue (nginx) |
| **TLS / HTTPS** | chiffrement ; certificat auto-signé = pas signé par une autorité → alerte navigateur normale |
| **php-fpm / FastCGI** | runtime PHP (interpréteur) qui écoute sur 9000 ; nginx lui parle en FastCGI |
| **wp-cli** | outil en ligne de commande pour WordPress (`wp core install`) |
| **Swap / swappiness / OOM killer** | mémoire de secours sur disque / tendance à swapper (0-100) / noyau qui tue un process quand la RAM est pleine |
| **Security Group** | pare-feu AWS au niveau de l'instance |
| **Elastic IP** | IP publique fixe AWS (sinon elle change à chaque stop/start) |
| **AMI** | image de disque de départ de l'EC2 (Ubuntu 22.04) |

---

## 12. Debug

### Lire un run
- Statuts d'une tâche

| Statut | Couleur | Sens |
|---|---|---|
| `ok` | vert | déjà conforme, rien touché |
| `changed` | jaune | a modifié le serveur → déclenche les notify |
| `skipping` | cyan | `when:` faux |
| `failed` | rouge | erreur → le play s'arrête **pour cet hôte** |
| `unreachable` | rouge | SSH impossible, la tâche n'a même pas commencé |
| `rescued` | — | échec rattrapé par un `rescue:` |
| `ignored` | — | échec masqué par `ignore_errors: true` |

- **Piège du RECAP** : `ok` **inclut** les `changed` → les compteurs ne s'additionnent pas.
- **Ordre de lecture** : `unreachable` → `failed` (lire le `fatal:` au-dessus) → `rescued`/`ignored` → `changed` (doit tomber à 0 au 2e run) → `skipped` → `ok`.
- **Code retour** (`echo $?`) : `0` OK, `2` au moins un failed, `4` au moins un unreachable.
- `escalation succeeded` = sudo a marché.
- Dernier vrai run (`run.log`) : `ok=40 changed=17 unreachable=0 failed=0 skipped=8`.

### Commandes de debug
```sh
ansible-playbook playbook.yml --ask-vault-pass -v      # résultat des modules
ansible-playbook playbook.yml --ask-vault-pass -vvv    # + commandes SSH
ansible-playbook playbook.yml --ask-vault-pass --check # simulation
ansible-playbook playbook.yml --ask-vault-pass --diff  # montre ce qui change dans les fichiers
ansible-playbook playbook.yml --ask-vault-pass -vvv 2>&1 | tee run.log
grep -nE 'fatal:|FAILED!|ERROR!|UNREACHABLE!|failed=[1-9]|unreachable=[1-9]' run.log

# Démo des erreurs (ne modifie rien) :
ANSIBLE_FORCE_COLOR=1 ansible-playbook Correc/error.yml --ask-vault-pass -v 2>&1 | tee error.log
less -R error.log
```

### `Correc/error.yml` (playbook de démo)
1. `ls` d'un dossier inexistant → `rc` ≠ 0, stderr (ignoré).
2. connexion TCP vers un port fermé → imite « MySQL pas prêt » (ignoré).
3. `until` qui n'aboutit jamais → `FAILED - RETRYING` ×3 (ignoré).
4. paquet apt inventé → erreur du module (ignoré).
5. `fail` volontaire → **arrête** le play, `failed=1`.
6. jamais exécutée.

### Problèmes classiques

| Symptôme | Cause / solution |
|---|---|
| `Permission denied (publickey)` | mauvais user (`ubuntu`) ou `.pem` pas en `chmod 400` |
| SSH timeout / `unreachable` | IP changée (`inventory.ini`), port 22 fermé dans le Security Group |
| Bloqué sur `Gathering Facts` alors que `ssh` marche | socket SSH multiplexé figé → `rm -rf ~/.ansible/cp` |
| Site injoignable mais SSH OK | 80/443 absents du Security Group |
| module `ufw` introuvable | `ansible-galaxy collection install -r requirements.yml` |
| `'mysql_root_password' is undefined` | `group_vars/webservers.yml` absent ou pas déchiffré |
| `Attempting to decrypt but no vault secrets found` | oubli de `--ask-vault-pass` |
| Conteneurs tués au hasard, très lent | RAM saturée → `free -m` (le rôle swap couvre ça) |
| Boucle de redirection WordPress | `fastcgi_param HTTPS on` manquant |
| `.pem` refusé sous WSL | clé sur `/mnt/c` → copier dans `~/.ssh` |

### Sur le serveur
```sh
sudo docker ps
cd /opt/wordpress && sudo docker compose logs -f mysql
sudo journalctl -u ssh -f          # voir les connexions SSH d'Ansible en direct
sudo journalctl -f | grep -i sudo  # voir les sudo
```

---

## 13. Correction / soutenance — question → preuve

> Remplacer `<IP>` par l'IP actuelle de l'EC2 (elle change si pas d'Elastic IP).
> Avant : démarrer l'instance sur la console AWS, vérifier l'IP dans `inventory.ini`, vérifier le Security Group.

**1. Seuls les ports nécessaires sont ouverts ?**
```sh
nmap -Pn <IP>                                  # 22, 80, 443 ; pas 3306
nc -zv -w5 <IP> 3306                           # échoue
nc -zv -w5 <IP> 443                            # marche
sudo ss -tlnp | grep 3306                      # (sur l'EC2) rien côté hôte
sudo docker exec wordpress-wordpress-1 sh -c 'php -r "var_dump(@fsockopen(\"mysql\", 3306));"'
                                               # marche : 3306 joignable SEULEMENT dans le réseau Docker
```
- 22 est indispensable : Ansible ne parle que par SSH, et l'accès root est exigé.

**2. Script de déploiement exécutable depuis une machine vers le serveur, à 2 endroits ?**
```sh
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --limit server2 --skip-tags ssh,ufw --ask-vault-pass   # 2e cible (inventory)
```
- décommenter `location = /preuve` dans `nginx.conf.j2` → `https://<IP>/preuve`.

**2.1 Idempotence ?** → relancer le playbook : `changed=0`.

**2.2 Rôles déployables indépendamment ?**
```sh
ansible webservers -b --ask-vault-pass -a "chdir=/opt/wordpress docker compose rm -sf phpmyadmin"
ansible-playbook playbook.yml --tags phpmyadmin --ask-vault-pass
```

**2.3 Pas de secret en dur ?**
```sh
grep -rn "password" --include='*.yml' --include='*.j2' --include='*.cfg' . | grep -v vault
head -1 group_vars/webservers.yml
ansible-vault view group_vars/webservers.yml
ansible server1 -b --ask-vault-pass -a "ls -l /opt/wordpress/.env"     # -rw------- root
```

**3. Cache des images / Dockerfile optimisé ?**
```sh
find . -name "Dockerfile*"                                  # rien
ansible server1 -b --ask-vault-pass -a "docker images"
```
- Que des `image:`, aucun `build:` → rien à rebuild. Si on avait un Dockerfile : `RUN apt install …` en haut (en cache), `COPY . /app` en bas (seule couche reconstruite).

**3.1 Un conteneur par service, qui communiquent ?**
```sh
ansible server1 -b --ask-vault-pass -a "chdir=/opt/wordpress docker compose ps"
ansible server1 -b --ask-vault-pass -a "docker network inspect wordpress_wp_network" | grep -E '"Name"|Driver|Subnet'
```

**3.2 Données dans des volumes, visibles par l'admin seulement ?**
```sh
ansible server1 -b --ask-vault-pass -a "docker volume ls"
ansible server1 -b --ask-vault-pass -a "docker volume inspect wordpress_wp_data"
ansible server1 -b --ask-vault-pass -a "ls -ld /var/lib/docker /var/lib/docker/volumes"   # drwx--x---
```
- Preuve de persistance : `docker compose down && docker compose up -d` → le site et la base sont toujours là.

**3.3 Tout lancer d'un coup / redémarrer un par un ?**
```sh
ansible server1 -b --ask-vault-pass -a "chdir=/opt/wordpress docker compose down"
ansible server1 -b --ask-vault-pass -a "chdir=/opt/wordpress docker compose up -d"
ansible server1 -b --ask-vault-pass -a "chdir=/opt/wordpress docker compose stop mysql"
ansible server1 -b --ask-vault-pass -a "chdir=/opt/wordpress docker compose start mysql"
# idem avec wordpress, phpmyadmin, nginx
```

**4. Le reboot** → `restart: always` + `docker` `enabled` + swap dans `fstab` → tout revient seul.

**Les 3 pages**
- `https://<IP>/` (site public)
- `https://<IP>/wp-admin` (user `thomas`, mot de passe dans le vault)
- `https://<IP>/phpmyadmin/` (user `wp_user` ou `root`, mots de passe dans le vault)
- Alerte « connexion non sécurisée » normale (auto-signé) → Avancé → Continuer.

**Rejouer la démo complète**
```sh
ansible-playbook teardown.yml --ask-vault-pass -e full_wipe=true   # taper "oui"
ansible-playbook playbook.yml --ask-vault-pass
```

**Machine neuve**
```sh
git clone https://github.com/Thomasrbm/Cloud-1.git && cd Cloud-1
sudo apt install -y ansible
ansible-galaxy collection install -r requirements.yml
ansible webservers -m ping --ask-vault-pass
```

---

## 14. Points faibles / incohérences repérés (à revoir)

- **⚠ Prioritaire — `run.log` est versionné et contient le mot de passe admin WordPress en clair**
  - Cause : le mode `-vvv` affiche la commande `wp core install --admin_password=…`.
  - À faire : retirer `run.log` du dépôt + l'ajouter au `.gitignore` ; mettre **`no_log: true`** sur la tâche « Install WordPress » ; changer ce mot de passe (`ansible-vault edit`) si le serveur tourne encore (il reste dans l'historique git).
- **Mots de passe passés en ligne de commande** (`--admin_password=…`) → visibles dans `ps` le temps de l'installation. Alternative : variable d'environnement ou `--prompt`.
- **IP différentes selon les fichiers** : `inventory.ini` = `13.60.244.93` ; `txt/CORREC.txt`, `txt/acces.txt`, `Correc/EXPLICATION.txt` (/preuve) = `13.60.218.238`. → pas d'Elastic IP ; à harmoniser.
- **`ansible.cfg`** : `remote_user = root` alors que le commentaire dit `ubuntu` (c'est l'inventaire qui le surcharge en `ubuntu`).
- **`txt/AWS.md`** : les commandes `teardown.yml` oublient `--ask-vault-pass`.
- **`txt/EXPLICATION_PROJET.txt`** : la liste des rôles oublie `swap`.
- **`phpmyadmin:latest`** non épinglé → un déploiement futur peut changer de version (les autres images sont versionnées).
- **`domain_name: localhost`** → le certificat a `CN=localhost` alors qu'on accède par IP.
- **Certificat valable 365 jours** et `creates:` → jamais renouvelé automatiquement.
- **`Correc/EXPLICATION.txt`** commence par une URL de connexion AWS (code OAuth) inutile → à supprimer.
- **Fin de `roles/wordpress/tasks/main.yml`** : commentaire coupé (« Rien n'est affiche quand la tache reussit ; »).
- **`--title={{ wp_site_title }}` sans guillemets** → casserait avec un titre contenant des espaces.
- **Commentaires** : mélange français/anglais et fautes de frappe (normal pour des notes perso, à nettoyer si rendu public).

---

## 15. Questions à me faire poser pour réviser

- Que se passe-t-il, dans l'ordre, quand je tape `ansible-playbook playbook.yml --ask-vault-pass` ?
- Pourquoi `group_vars/webservers.yml` est dans git alors que ce sont des mots de passe ?
- Différence entre `{{ mysql_password }}` et `${MYSQL_PASSWORD}` ? Qui remplace quoi, où, quand ?
- Pourquoi `teardown.yml` demande le mot de passe du vault alors qu'il n'utilise aucun secret ?
- Pourquoi un `command:` n'est pas idempotent, et comment on l'a rendu idempotent ?
- Différence `ok` / `changed` ? Pourquoi `ok=40 changed=17` ne fait pas 57 tâches ?
- Quand un handler s'exécute-t-il ? Combien de fois ? Que se passe-t-il si le play échoue avant ?
- Pourquoi `--force-recreate` dans `Recreate stack` ?
- Pourquoi les rôles db/wordpress/phpmyadmin utilisent des `-f` explicites et pas proxy ?
- Pourquoi le rôle proxy est-il en dernier ?
- Comment nginx parle à WordPress ? Et à phpMyAdmin ? Pourquoi deux mécanismes différents (FastCGI vs proxy_pass) ?
- Pourquoi `fastcgi_param HTTPS on` ?
- Pourquoi nginx et WordPress partagent le volume `wp_data` ?
- Qu'est-ce qu'un profile Compose et pourquoi `wpcli` en a un ? Pourquoi `user: 33:33` ?
- Différence `docker compose run` / `exec` ?
- Volume nommé vs bind mount : lesquels on utilise et pourquoi ?
- Comment prouver que MySQL n'est pas accessible d'Internet mais l'est depuis WordPress ?
- Pourquoi deux pare-feu (Security Group + UFW) ?
- Pourquoi du swap ? Pourquoi `swappiness=10` ? Pourquoi `mkswap` seulement à la création ?
- Comment l'accès root est-il débloqué sur une AMI AWS ? Pourquoi `validate: sshd -t` ?
- Pourquoi une clé publique par machine plutôt que partager le `.pem` ?
- Pourquoi aucune image custom / aucun Dockerfile ? Comment ordonner un Dockerfile pour le cache ?
- Pourquoi `wordpress:php8.1-fpm` et pas `wordpress:apache` ?
- Que fait `pipelining = True` ? Et `ControlPersist` ?
- Comment déployer sur un 2e serveur ? Comment redéployer seulement phpMyAdmin ?
- Que se passe-t-il au reboot du serveur ?
- Quels sont les points faibles du projet (section 14) et comment les corriger ?
