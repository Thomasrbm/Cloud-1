# roles/<NOM_ROLE>/tasks/main.yml (briques de tâches)

- Liste des actions d'un rôle
- Chaque tâche = un `name` + un module + ses paramètres
- Toutes les briques réutilisables dans un seul fichier, à piocher

```yaml
---
# ==============================================================================
# RÔLE <NOM_ROLE>
# <CE_QUE_FAIT_LE_ROLE>
# ==============================================================================


# ------------------------------------------------------------------------------
# INSTALLER DES PAQUETS
# ------------------------------------------------------------------------------
- name: Install packages
  # gestionnaire de paquets Ubuntu/Debian
  apt:
    # liste des paquets
    name:
      - <PAQUET_1>
      - <PAQUET_2>
    # present = installe s'ils manquent / absent = désinstalle / latest = met à jour
    state: present
    # fait un "apt update" avant
    update_cache: true


# ------------------------------------------------------------------------------
# CRÉER DES DOSSIERS (avec une boucle)
# ------------------------------------------------------------------------------
- name: Create directories
  # crée / supprime / règle les droits d'un fichier ou dossier
  file:
    # item prend tour à tour chaque valeur de loop
    path: "{{ item }}"
    # directory = dossier / absent = supprime / touch = fichier vide
    state: directory
    # droits : root écrit, tout le monde lit et entre
    mode: '0755'
  # répète la tâche pour chaque élément
  loop:
    - "{{ project_dir }}"
    - "{{ project_dir }}/<SOUS_DOSSIER>"


# ------------------------------------------------------------------------------
# DÉPOSER UN TEMPLATE JINJA2
# ------------------------------------------------------------------------------
- name: Deploy <FICHIER>
  # remplace les {{ variables }} du .j2 puis envoie le fichier
  template:
    # cherché dans roles/<NOM_ROLE>/templates/
    src: <FICHIER>.j2
    # chemin final sur le serveur
    dest: "{{ project_dir }}/<FICHIER>"
    # lisible par tous (mettre '0600' pour un fichier de secrets)
    mode: '0644'
  # si le fichier a changé, lance ce handler en fin de play
  notify: <NOM_HANDLER>


# ------------------------------------------------------------------------------
# COPIER UN FICHIER TEL QUEL
# ------------------------------------------------------------------------------
- name: Copy <FICHIER>
  copy:
    # cherché dans roles/<NOM_ROLE>/files/
    src: <FICHIER>
    dest: <CHEMIN_DEST>
    # propriétaire sur le serveur
    owner: root
    group: root
    mode: '0644'


# ------------------------------------------------------------------------------
# LANCER UN CONTENEUR SANS FAUX "CHANGED" (idempotence)
# ------------------------------------------------------------------------------
- name: Start <NOM_SERVICE>
  # -f = fichiers compose à fusionner / up -d = démarre en arrière-plan
  command: docker compose -f docker-compose.yml -f compose.<NOM_SERVICE>.yml up -d <NOM_SERVICE>
  args:
    # se place dans ce dossier avant de lancer la commande
    chdir: "{{ project_dir }}"
  # garde le résultat dans la variable svc_up
  register: svc_up
  # par défaut command dit toujours "changed"
  # ici seulement si Docker a vraiment créé / démarré / recréé le conteneur
  changed_when: >
    ('Started' in svc_up.stderr) or ('Created' in svc_up.stderr)
    or ('Recreated' in svc_up.stderr)


# ------------------------------------------------------------------------------
# COMMANDE EXÉCUTÉE UNE SEULE FOIS (ex : certificat TLS auto-signé)
# ------------------------------------------------------------------------------
# openssl req -x509   = crée un certificat auto-signé
# -nodes              = clé sans mot de passe (sinon nginx bloque au démarrage)
# -days 365           = valable un an
# -newkey rsa:2048    = nouvelle clé RSA 2048 bits
# -keyout / -out      = où écrire la clé privée / le certificat
# -subj               = infos du certificat sans questions (CN = domaine)
- name: Generate self-signed certificate
  command: >
    openssl req -x509 -nodes -days 365 -newkey rsa:2048
    -keyout {{ project_dir }}/ssl/key.pem
    -out {{ project_dir }}/ssl/cert.pem
    -subj "/C=<PAYS>/ST=<REGION>/L=<VILLE>/O=<ORGA>/CN={{ domain_name }}"
  args:
    # si ce fichier existe déjà, la tâche est sautée
    creates: "{{ project_dir }}/ssl/cert.pem"


# ------------------------------------------------------------------------------
# ATTENDRE QU'UN SERVICE SOIT PRÊT + VRAI MESSAGE D'ERREUR
# ------------------------------------------------------------------------------
# exemples de <COMMANDE_DE_TEST> :
#   MySQL   : mysqladmin ping -uroot -p"$MYSQL_ROOT_PASSWORD" --silent
#   fichier : test -f <CHEMIN_FICHIER>
#   HTTP    : curl -fsS http://localhost:<PORT>/
- name: Wait for <NOM_SERVICE>
  # shell = comme command mais accepte pipes et variables du shell
  # exec -T = commande dans un conteneur déjà lancé, sans terminal interactif
  shell: >-
    docker compose exec -T <NOM_SERVICE>
    sh -c '<COMMANDE_DE_TEST>'
  args:
    chdir: "{{ project_dir }}"
  register: ping
  # recommence tant que le code retour n'est pas 0 (0 = succès)
  until: ping.rc == 0
  # 30 essais x 5 secondes = 150 s max
  retries: 30
  delay: 5
  # ne compte jamais comme un changement
  changed_when: false
  # ne plante pas ici, l'erreur est gérée juste en dessous
  failed_when: false

- name: Fail with a clear message
  # arrête le playbook avec un message clair
  fail:
    msg: "<NOM_SERVICE> n'a pas répondu. Vérifier : docker compose logs <NOM_SERVICE>"
  # seulement si le dernier essai a échoué
  when: ping.rc != 0


# ------------------------------------------------------------------------------
# VÉRIFIER AVANT D'INSTALLER
# ------------------------------------------------------------------------------
- name: Check whether <APP> is installed
  command: <COMMANDE_CHECK>
  register: is_installed
  # teste seulement : ne change rien, ne plante jamais
  changed_when: false
  failed_when: false

- name: Install <APP>
  command: <COMMANDE_INSTALL>
  # installe seulement si le test a échoué
  when: is_installed.rc != 0
  register: install
  # "changed" si l'installation a réussi
  changed_when: install.rc == 0


# ------------------------------------------------------------------------------
# CONTENEUR OUTIL LANCÉ À LA DEMANDE (ex : wp-cli)
# ------------------------------------------------------------------------------
# --profile tools = active les services "profiles: [tools]" (ignorés par un simple up)
# run             = crée un conteneur neuf juste pour cette commande
# --rm            = le supprime dès que la commande est finie
# -T              = pas de terminal interactif
- name: Run a one-shot tool container
  command: >-
    docker compose --profile tools run --rm -T <SERVICE_OUTIL> <COMMANDE>
  args:
    chdir: "{{ project_dir }}"


# ------------------------------------------------------------------------------
# GROUPER DES TÂCHES SOUS UNE CONDITION
# ------------------------------------------------------------------------------
- name: <GROUPE_DE_TACHES>
  # condition appliquée à toutes les tâches du bloc (| bool = convertit en vrai/faux)
  when: <VARIABLE> | bool
  block:
    - name: <TACHE_1>
      <MODULE>: <PARAMS>
    - name: <TACHE_2>
      <MODULE>: <PARAMS>


# ------------------------------------------------------------------------------
# MODIFIER UNE LIGNE D'UN FICHIER DE CONFIG
# ------------------------------------------------------------------------------
- name: Set <OPTION>
  # garantit qu'une ligne précise existe
  lineinfile:
    path: <FICHIER_CONF>
    # ligne à remplacer (^#? attrape aussi la version commentée)
    regexp: '^#?\s*<OPTION>'
    # nouvelle ligne
    line: '<OPTION> <VALEUR>'
    # teste le fichier avant de l'écrire (%s = fichier temporaire), ex : sshd -t -f %s
    validate: '<COMMANDE_VALIDATION> %s'
  notify: <NOM_HANDLER>


# ------------------------------------------------------------------------------
# GÉRER UN SERVICE SYSTÈME
# ------------------------------------------------------------------------------
- name: Ensure <SERVICE> is running
  service:
    name: <SERVICE>
    # started / stopped / restarted / reloaded
    state: started
    # démarre automatiquement au boot
    enabled: true


# ------------------------------------------------------------------------------
# AFFICHER ET VÉRIFIER
# ------------------------------------------------------------------------------
- name: Show value
  # affiche un message ou une variable
  debug:
    msg: "{{ <VARIABLE> }}"

- name: Guard
  # arrête tout si la condition est fausse
  assert:
    that:
      - <CONDITION>
    fail_msg: "<MESSAGE>"
```

## Mots-clés à retenir

- `register` : garde le résultat (`.rc`, `.stdout`, `.stderr`, `.changed`)
- `when` : condition
- `loop` : boucle, valeur courante = `{{ item }}`
- `with_fileglob` : boucle sur des fichiers (ex : `*.pub`)
- `changed_when` / `failed_when` : redéfinissent "changed" / "failed"
- `notify` : appelle un handler si la tâche a changé quelque chose
- `args: chdir` : dossier où lancer la commande
- `args: creates` : saute la tâche si le fichier existe
- `become: true` : exécute en root
- `>` : texte multi-lignes lu en une ligne (avec retour à la ligne final)
- `>-` : pareil, sans retour à la ligne final
- Attention : un `#` à l'intérieur d'un bloc `>` ou `>-` n'est PAS un commentaire, il fait partie de la commande
