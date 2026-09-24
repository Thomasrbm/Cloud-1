# Service systemd (lancer un programme sans Docker)

- systemd = gestionnaire de services de Linux
- Lance le programme au boot, le relance s'il plante, garde ses logs
- Remplace le `restart: always` de docker compose

## Fichier d'unité : /etc/systemd/system/<NOM_SERVICE>.service

```ini
# ------------------------------------------------------------------------------
# [Unit] : description et dépendances
# ------------------------------------------------------------------------------
[Unit]
# texte affiché dans "systemctl status"
Description=<DESCRIPTION_SERVICE>
# démarre après que le réseau soit prêt
After=network.target

# ------------------------------------------------------------------------------
# [Service] : comment lancer le programme
# ------------------------------------------------------------------------------
[Service]
# simple = le programme reste au premier plan (cas le plus courant)
Type=simple

# utilisateur qui fait tourner le programme (éviter root si possible)
User=<UTILISATEUR_SERVICE>
Group=<GROUPE_SERVICE>

# dossier courant du programme
WorkingDirectory=<DOSSIER_APP>

# fichier de variables d'environnement (format CLE=valeur, une par ligne)
# lu par systemd en root AVANT de lancer le programme -> peut être en 0600 root
EnvironmentFile=<CHEMIN_FICHIER_ENV>

# variable d'environnement écrite en dur (visible par "systemctl show", à éviter pour un secret)
# Environment=<CLE>=<VALEUR>

# commande complète, chemin ABSOLU obligatoire
ExecStart=<CHEMIN_ABSOLU_INTERPRETEUR> <CHEMIN_ABSOLU_SCRIPT>

# relance si le programme s'arrête en erreur (crash)
# always = relance même après un arrêt normal
Restart=on-failure
# attend 2 secondes avant de relancer
RestartSec=2

# ------------------------------------------------------------------------------
# [Install] : quand l'activer
# ------------------------------------------------------------------------------
[Install]
# "enabled" = démarré au boot, avec les services normaux du système
WantedBy=multi-user.target
```

## Tâches Ansible correspondantes

```yaml
# (facultatif) utilisateur système dédié, sans shell ni connexion
- name: Create service user
  user:
    name: <UTILISATEUR_SERVICE>
    system: true
    shell: /usr/sbin/nologin
    create_home: false

# dépose le fichier d'unité (copy + content car pas de templates/)
- name: Deploy systemd unit
  copy:
    dest: /etc/systemd/system/<NOM_SERVICE>.service
    owner: root
    group: root
    mode: '0644'
    content: |
      [Unit]
      Description=<DESCRIPTION_SERVICE>
      After=network.target

      [Service]
      Type=simple
      User=<UTILISATEUR_SERVICE>
      EnvironmentFile=<CHEMIN_FICHIER_ENV>
      ExecStart=<CHEMIN_ABSOLU_INTERPRETEUR> <CHEMIN_ABSOLU_SCRIPT>
      Restart=on-failure
      RestartSec=2

      [Install]
      WantedBy=multi-user.target
  register: unit_file

# daemon_reload : systemd relit ses fichiers d'unité (obligatoire après modif)
# enabled : démarré au boot / started : lancé maintenant s'il ne tourne pas
- name: Enable and start the service
  systemd:
    name: <NOM_SERVICE>
    daemon_reload: true
    enabled: true
    state: started

# redémarre seulement si l'unité, le code ou l'env ont changé
- name: Restart the service if something changed
  systemd:
    name: <NOM_SERVICE>
    state: restarted
  when: (unit_file is changed) or (<AUTRE_RESULTAT> is changed)
```

## Commandes utiles sur le serveur

```bash
# état du service (actif ? enabled ? derniers logs)
systemctl status <NOM_SERVICE>

# logs du service en direct
journalctl -u <NOM_SERVICE> -f

# après modif manuelle d'un .service
systemctl daemon-reload

# démarrer / arrêter / redémarrer
systemctl start <NOM_SERVICE>
systemctl stop <NOM_SERVICE>
systemctl restart <NOM_SERVICE>

# démarré au boot ? (enabled / disabled)
systemctl is-enabled <NOM_SERVICE>

# tester la relance auto : tue le process, il doit revenir en quelques secondes
systemctl kill -s SIGKILL <NOM_SERVICE>
```
