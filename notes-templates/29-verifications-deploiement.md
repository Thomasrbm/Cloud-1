# Checklist de vérification d'un déploiement

```bash
# ------------------------------------------------------------------------------
# Depuis TA machine
# ------------------------------------------------------------------------------

# 1er lancement sur serveur vierge : doit finir sans "failed"
ansible-playbook <PLAYBOOK>.yml

# 2e lancement : doit passer aussi, idéalement avec changed=0
ansible-playbook <PLAYBOOK>.yml

# la page d'accueil répond
curl -s http://<IP_SERVEUR>/

# le chemin proxifié répond en JSON
curl -s http://<IP_SERVEUR>/<CHEMIN_API>/

# le port interne NE doit PAS répondre depuis l'extérieur (connexion refusée attendue)
curl -m 5 http://<IP_SERVEUR>:<PORT_BACK>/

# aucun secret en clair dans le dépôt (aucun résultat attendu)
grep -r "<VALEUR_DU_SECRET>" .

# ------------------------------------------------------------------------------
# Sur le SERVEUR
# ------------------------------------------------------------------------------

# ports en écoute : le programme doit être sur 127.0.0.1:<PORT_BACK>, nginx sur 0.0.0.0:80
ss -tlnp

# service actif + enabled
systemctl status <NOM_SERVICE>
systemctl is-enabled <NOM_SERVICE> nginx

# relance auto après crash : tuer le process puis revérifier quelques secondes après
systemctl kill -s SIGKILL <NOM_SERVICE>
systemctl status <NOM_SERVICE>

# droits du fichier de secret (-rw------- root root attendu)
ls -l <CHEMIN_FICHIER_ENV>

# après reboot, tout doit revenir tout seul
reboot
```

```bash
# puis, une fois le serveur revenu, depuis ta machine
curl -s http://<IP_SERVEUR>/<CHEMIN_API>/
```
