# Passer un secret à un programme (fichier d'env + no_log)

- Le secret vient du vault
- Il est écrit sur le serveur dans un fichier lisible par root seulement
- systemd le lit et le donne au programme en variable d'environnement
- `no_log: true` l'empêche d'apparaître dans la sortie d'Ansible

## Fichier d'env sur le serveur

```yaml
# dossier de config de l'appli
- name: Create config directory
  file:
    path: <DOSSIER_CONFIG>
    state: directory
    owner: root
    group: root
    mode: '0700'

# fichier CLE=valeur, 0600 root:root = seul root peut le lire
# systemd le lit en root avant de lancer le programme, même si le programme tourne sous un autre user
# no_log : cache le contenu dans la sortie (sinon visible avec -v ou --diff)
- name: Deploy environment file with the secret
  copy:
    dest: <CHEMIN_FICHIER_ENV>
    owner: root
    group: root
    mode: '0600'
    content: |
      <NOM_VAR_ENV>={{ <VARIABLE_SECRETE> }}
  no_log: true
  register: env_file
```

## no_log : ce qu'il faut savoir

```yaml
# sans no_log, Ansible peut afficher les paramètres de la tâche (dont le secret)
# dans les erreurs, en mode -v, avec --diff, ou dans les logs
- name: <TACHE_QUI_MANIPULE_UN_SECRET>
  <MODULE>:
    <PARAM>: "{{ <VARIABLE_SECRETE> }}"
  # la sortie devient "the output has been hidden due to the fact that 'no_log: true'..."
  no_log: true
  # (débogage) désactiver temporairement pour voir l'erreur, puis remettre
  # no_log: false
```

## Côté programme : lire une variable d'environnement

```text
Python  : os.environ.get("<NOM_VAR_ENV>")
Node.js : process.env.<NOM_VAR_ENV>
Go      : os.Getenv("<NOM_VAR_ENV>")
Bash    : "$<NOM_VAR_ENV>"
```

## Vérifier sur le serveur

```bash
# droits du fichier : doit afficher -rw------- root root
ls -l <CHEMIN_FICHIER_ENV>

# un utilisateur normal ne doit PAS pouvoir le lire
sudo -u nobody cat <CHEMIN_FICHIER_ENV>

# le repo ne doit contenir le secret nulle part en clair
grep -r "<VALEUR_DU_SECRET>" .
```
