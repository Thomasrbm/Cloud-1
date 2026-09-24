# roles/<NOM_ROLE>/tasks/main.yml (les briques de tâches)

## À quoi ça sert

C'est la liste des actions d'un rôle. Chaque tâche = un `name` + un module + ses paramètres. Voici les briques réutilisables, à combiner.

## Structure d'une tâche

```yaml
- name: <DESCRIPTION_TACHE>
  <MODULE>:
    <PARAM>: <VALEUR>
```

- `- name:` : texte affiché pendant l'exécution
- `<MODULE>:` : l'outil utilisé (apt, file, template, command...)
- `<PARAM>: <VALEUR>` : options du module

## Installer des paquets

```yaml
- name: Install packages
  apt:
    name:
      - <PAQUET_1>
      - <PAQUET_2>
    state: present
    update_cache: true
```

- `apt:` : gestionnaire de paquets Ubuntu/Debian
- `name:` : liste des paquets
- `state: present` : installe s'ils manquent. `absent` = désinstalle, `latest` = met à jour
- `update_cache: true` : fait un `apt update` avant

## Créer des dossiers

```yaml
- name: Create directories
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - "{{ project_dir }}"
    - "{{ project_dir }}/<SOUS_DOSSIER>"
```

- `file:` : crée, supprime ou règle les droits d'un fichier ou dossier
- `path: "{{ item }}"` : `item` prend tour à tour chaque valeur de `loop`
- `state: directory` : doit être un dossier. `absent` = supprime, `touch` = crée un fichier vide
- `mode: '0755'` : droits (root écrit, tout le monde lit et entre)
- `loop:` : répète la tâche pour chaque élément de la liste

## Déposer un template

```yaml
- name: Deploy <FICHIER>
  template:
    src: <FICHIER>.j2
    dest: "{{ project_dir }}/<FICHIER>"
    mode: '0644'
  notify: <NOM_HANDLER>
```

- `template:` : remplace les `{{ variables }}` du `.j2` puis envoie le fichier sur le serveur
- `src:` : cherché dans `roles/<NOM_ROLE>/templates/`
- `dest:` : chemin final sur le serveur
- `mode: '0644'` : lisible par tous. Mets `'0600'` pour un fichier de secrets
- `notify:` : si le fichier a changé, lance le handler de ce nom en fin de play

## Copier un fichier tel quel

```yaml
- name: Copy <FICHIER>
  copy:
    src: <FICHIER>
    dest: <CHEMIN_DEST>
    owner: root
    group: root
    mode: '0644'
```

- `copy:` : envoie le fichier sans rien remplacer
- `src:` : cherché dans `roles/<NOM_ROLE>/files/`
- `owner` / `group` : propriétaire du fichier sur le serveur

## Lancer un conteneur sans faux "changed"

```yaml
- name: Start <NOM_SERVICE>
  command: docker compose -f docker-compose.yml -f compose.<NOM_SERVICE>.yml up -d <NOM_SERVICE>
  args:
    chdir: "{{ project_dir }}"
  register: svc_up
  changed_when: >
    ('Started' in svc_up.stderr) or ('Created' in svc_up.stderr)
    or ('Recreated' in svc_up.stderr)
```

- `command:` : lance une commande sur le serveur
- `-f ...` : fichiers compose à fusionner
- `up -d <NOM_SERVICE>` : démarre ce service en arrière-plan
- `chdir:` : se place dans ce dossier avant de lancer la commande
- `register: svc_up` : garde le résultat dans la variable `svc_up`
- `changed_when:` : par défaut `command` dit toujours "changed". Ici, seulement si Docker a vraiment créé ou redémarré le conteneur
- `>` : écrit sur plusieurs lignes, lu comme une seule

## Commande exécutée une seule fois

```yaml
- name: Generate self-signed certificate
  command: >
    openssl req -x509 -nodes -days 365 -newkey rsa:2048
    -keyout {{ project_dir }}/ssl/key.pem
    -out {{ project_dir }}/ssl/cert.pem
    -subj "/C=<PAYS>/ST=<REGION>/L=<VILLE>/O=<ORGA>/CN={{ domain_name }}"
  args:
    creates: "{{ project_dir }}/ssl/cert.pem"
```

- `openssl req -x509` : crée un certificat auto-signé
- `-nodes` : clé privée sans mot de passe (sinon nginx bloque au démarrage)
- `-days 365` : valable un an
- `-newkey rsa:2048` : génère une nouvelle clé RSA de 2048 bits
- `-keyout` : où écrire la clé privée
- `-out` : où écrire le certificat
- `-subj` : infos du certificat sans questions interactives. `CN` = nom du domaine
- `creates:` : si ce fichier existe déjà, la tâche est sautée

## Attendre qu'un service soit prêt

```yaml
- name: Wait for <NOM_SERVICE>
  shell: >-
    docker compose exec -T <NOM_SERVICE>
    sh -c '<COMMANDE_DE_TEST>'
  args:
    chdir: "{{ project_dir }}"
  register: ping
  until: ping.rc == 0
  retries: 30
  delay: 5
  changed_when: false
  failed_when: false

- name: Fail with a clear message
  fail:
    msg: "<NOM_SERVICE> n'a pas répondu. Vérifier : docker compose logs <NOM_SERVICE>"
  when: ping.rc != 0
```

- `shell:` : comme `command`, mais accepte les pipes et variables du shell
- `exec -T` : lance une commande dans un conteneur déjà démarré, sans terminal interactif
- `until: ping.rc == 0` : recommence tant que le code retour n'est pas 0 (0 = succès)
- `retries: 30` : 30 essais maximum
- `delay: 5` : 5 secondes entre chaque essai, donc 150 s au total
- `changed_when: false` : ne compte jamais comme un changement
- `failed_when: false` : ne plante pas ici, on gère l'erreur à la tâche suivante
- `fail:` : arrête le playbook avec un message clair
- `when: ping.rc != 0` : seulement si le dernier essai a échoué

Exemples de `<COMMANDE_DE_TEST>` :

- MySQL : `mysqladmin ping -uroot -p"$MYSQL_ROOT_PASSWORD" --silent`
- Fichier présent : `test -f <CHEMIN_FICHIER>`
- HTTP : `curl -fsS http://localhost:<PORT>/`

## Vérifier avant d'installer

```yaml
- name: Check whether <APP> is installed
  command: <COMMANDE_CHECK>
  register: is_installed
  changed_when: false
  failed_when: false

- name: Install <APP>
  command: <COMMANDE_INSTALL>
  when: is_installed.rc != 0
  register: install
  changed_when: install.rc == 0
```

- Première tâche : teste seulement, ne change rien et ne plante jamais
- `when: is_installed.rc != 0` : installe seulement si le test a échoué
- `changed_when: install.rc == 0` : "changed" si l'installation a réussi

## Conteneur outil lancé à la demande

```yaml
- name: Run a one-shot tool container
  command: >-
    docker compose --profile tools run --rm -T <SERVICE_OUTIL> <COMMANDE>
  args:
    chdir: "{{ project_dir }}"
```

- `--profile tools` : active les services marqués `profiles: [tools]`, ignorés par un simple `up`
- `run` : crée un nouveau conteneur juste pour cette commande
- `--rm` : le supprime dès que la commande est finie
- `-T` : pas de terminal interactif

## Grouper des tâches sous une condition

```yaml
- name: <GROUPE_DE_TACHES>
  when: <VARIABLE> | bool
  block:
    - name: <TACHE_1>
      <MODULE>: <PARAMS>
    - name: <TACHE_2>
      <MODULE>: <PARAMS>
```

- `block:` : groupe de tâches
- `when:` : condition appliquée à toutes les tâches du bloc
- `| bool` : convertit la valeur en vrai/faux

## Modifier une ligne dans un fichier de config

```yaml
- name: Set <OPTION>
  lineinfile:
    path: <FICHIER_CONF>
    regexp: '^#?\s*<OPTION>'
    line: '<OPTION> <VALEUR>'
    validate: '<COMMANDE_VALIDATION> %s'
  notify: <NOM_HANDLER>
```

- `lineinfile:` : garantit qu'une ligne précise existe
- `regexp:` : ligne à remplacer. `^#?` attrape aussi la version commentée
- `line:` : nouvelle ligne
- `validate:` : teste le fichier avant de l'écrire. `%s` = le fichier temporaire. Ex : `sshd -t -f %s`

## Gérer un service système

```yaml
- name: Ensure <SERVICE> is running
  service:
    name: <SERVICE>
    state: started
    enabled: true
```

- `state: started` : le démarre s'il est arrêté. Aussi `stopped`, `restarted`, `reloaded`
- `enabled: true` : le démarre automatiquement au boot

## Afficher et vérifier

```yaml
- name: Show value
  debug:
    msg: "{{ <VARIABLE> }}"

- name: Guard
  assert:
    that:
      - <CONDITION>
    fail_msg: "<MESSAGE>"
```

- `debug:` : affiche un message ou une variable
- `assert:` : arrête tout si la condition est fausse

## Mots-clés à retenir

- `register` : garde le résultat (`.rc`, `.stdout`, `.stderr`, `.changed`)
- `when` : condition
- `loop` : boucle, la valeur courante est `{{ item }}`
- `with_fileglob` : boucle sur des fichiers (ex : `*.pub`)
- `changed_when` / `failed_when` : redéfinissent quand c'est "changed" ou "failed"
- `notify` : appelle un handler si la tâche a changé quelque chose
- `args: chdir` : dossier où lancer la commande
- `args: creates` : saute la tâche si le fichier existe
- `become: true` : exécute en root
- `tags` : étiquettes pour `--tags`
- `>` : texte multi-lignes lu en une ligne, avec un retour à la ligne final
- `>-` : pareil, sans retour à la ligne final
