# roles/<NOM_ROLE>/tasks/main.yml — patterns de tâches

## Squelette

```yaml
---
# ==============================================================================
# RÔLE <NOM_ROLE>
# <CE_QUE_FAIT_LE_ROLE>
# Déployable seul : ansible-playbook playbook.yml --tags <TAG> --ask-vault-pass
# ==============================================================================

- name: <DESCRIPTION_TACHE>
  <MODULE>:
    <PARAM>: <VALEUR>
```

## Installer des paquets (apt)

```yaml
- name: Install packages
  apt:
    name:
      - <PAQUET_1>
      - <PAQUET_2>
    state: present          # present | absent | latest
    update_cache: true      # = apt update
```

## Créer un dossier / des dossiers (file + loop)

```yaml
- name: Create directories
  file:
    path: "{{ item }}"
    state: directory        # directory | absent | touch | file
    mode: '0755'
  loop:
    - "{{ project_dir }}"
    - "{{ project_dir }}/<SOUS_DOSSIER>"
```

## Déposer un template Jinja2 (+ handler si changement)

```yaml
- name: Deploy <FICHIER>
  template:
    src: <FICHIER>.j2                   # dans roles/<NOM_ROLE>/templates/
    dest: "{{ project_dir }}/<FICHIER>"
    mode: '0644'                        # 0600 pour un .env / secret
  notify: <NOM_HANDLER>
```

## Copier un fichier tel quel

```yaml
- name: Copy <FICHIER>
  copy:
    src: <FICHIER>                      # dans roles/<NOM_ROLE>/files/
    dest: <CHEMIN_DEST>
    owner: root
    group: root
    mode: '0644'
```

## Commande idempotente (docker compose up)

```yaml
- name: Start <NOM_SERVICE>
  command: docker compose -f docker-compose.yml -f compose.<NOM_SERVICE>.yml up -d <NOM_SERVICE>
  args:
    chdir: "{{ project_dir }}"
  register: svc_up
  # "changed" uniquement si docker a vraiment bougé quelque chose
  changed_when: >
    ('Started' in svc_up.stderr) or ('Created' in svc_up.stderr)
    or ('Recreated' in svc_up.stderr)
```

## Commande qui ne tourne qu'une fois (creates)

```yaml
- name: Generate self-signed certificate
  command: >
    openssl req -x509 -nodes -days 365 -newkey rsa:2048
    -keyout {{ project_dir }}/ssl/key.pem
    -out {{ project_dir }}/ssl/cert.pem
    -subj "/C=<PAYS>/ST=<REGION>/L=<VILLE>/O=<ORGA>/CN={{ domain_name }}"
  args:
    creates: "{{ project_dir }}/ssl/cert.pem"   # sautée si le fichier existe
```

## Attendre qu'un service réponde (until / retries) + vrai fail

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

Exemples de `<COMMANDE_DE_TEST>` :
- MySQL : `mysqladmin ping -uroot -p"$MYSQL_ROOT_PASSWORD" --silent`
- Fichier présent : `test -f <CHEMIN_FICHIER>`
- HTTP : `curl -fsS http://localhost:<PORT>/`

## Tester avant d'agir (check puis action conditionnelle)

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

## Conteneur outil ponctuel (profile compose)

```yaml
- name: Run a one-shot tool container
  command: >-
    docker compose --profile tools run --rm -T <SERVICE_OUTIL> <COMMANDE>
  args:
    chdir: "{{ project_dir }}"
```

## Bloc conditionnel

```yaml
- name: <GROUPE_DE_TACHES>
  when: <VARIABLE> | bool
  block:
    - name: <TACHE_1>
      <MODULE>: ...
    - name: <TACHE_2>
      <MODULE>: ...
```

## Modifier une ligne d'un fichier de config

```yaml
- name: Set <OPTION>
  lineinfile:
    path: <FICHIER_CONF>
    regexp: '^#?\s*<OPTION>'
    line: '<OPTION> <VALEUR>'
    validate: '<COMMANDE_VALIDATION> %s'   # ex: sshd -t -f %s
  notify: <NOM_HANDLER>
```

## Service systemd

```yaml
- name: Ensure <SERVICE> is running
  service:
    name: <SERVICE>
    state: started      # started | stopped | restarted | reloaded
    enabled: true       # démarre au boot
```

## Afficher / vérifier

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

## Mots-clés utiles

| Mot-clé | Effet |
|---|---|
| `register` | stocke le résultat (`.rc`, `.stdout`, `.stderr`, `.changed`) |
| `when` | condition |
| `loop` / `with_fileglob` | boucle (`{{ item }}`) |
| `changed_when` / `failed_when` | redéfinit changed / failed |
| `notify` | déclenche un handler en fin de play si changed |
| `args: chdir / creates` | dossier d'exécution / idempotence |
| `become: true` | sudo |
| `tags` | filtrage avec `--tags` |
| `>` / `>-` | chaîne multi-lignes (avec / sans `\n` final) |
