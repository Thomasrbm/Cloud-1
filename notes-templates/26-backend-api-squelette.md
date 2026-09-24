# Backend : squelette d'API HTTP JSON (sans framework, sans Docker)

- Python 3 est déjà installé sur Debian/Ubuntu → aucune dépendance à installer
- Le script est déposé par Ansible (`copy: content:`), lancé par systemd
- À compléter avec ta propre logique

## Script : <DOSSIER_APP>/<NOM_SCRIPT>.py

```python
#!/usr/bin/env python3
# serveur HTTP de la bibliothèque standard (rien à installer)
from http.server import BaseHTTPRequestHandler, HTTPServer
# pour transformer un dict Python en texte JSON
import json
# pour lire les variables d'environnement
import os

# adresse d'écoute : 127.0.0.1 = joignable seulement depuis la machine elle-même
# 0.0.0.0 = joignable depuis l'extérieur
HOST = "<ADRESSE_ECOUTE>"
# port d'écoute (int obligatoire)
PORT = int("<PORT>")


# une classe = ce que fait le serveur à chaque requête
class Handler(BaseHTTPRequestHandler):

    # appelé pour chaque requête GET
    def do_GET(self):
        # contenu de la réponse (dict Python)
        body = {
            "<CLE_1>": "<VALEUR_1>",
            "<CLE_2>": <EXPRESSION_2>,
        }
        # dict -> texte JSON -> octets
        data = json.dumps(body).encode()

        # code HTTP 200 = OK
        self.send_response(200)
        # dit au navigateur que c'est du JSON
        self.send_header("Content-Type", "application/json")
        # taille de la réponse
        self.send_header("Content-Length", str(len(data)))
        # fin des en-têtes
        self.end_headers()
        # envoie le corps
        self.wfile.write(data)

    # (facultatif) coupe les logs de chaque requête dans journalctl
    def log_message(self, format, *args):
        pass


# point d'entrée : crée le serveur et tourne à l'infini
if __name__ == "__main__":
    HTTPServer((HOST, PORT), Handler).serve_forever()
```

## Tâches Ansible pour le déposer

```yaml
# dossier de l'application
- name: Create app directory
  file:
    path: <DOSSIER_APP>
    state: directory
    owner: root
    group: root
    mode: '0755'

# dépose le script ; les {{ variables }} dans content sont remplacées
# (ex : PORT = int("{{ <VARIABLE_PORT> }}") pour ne rien écrire en dur)
- name: Deploy backend script
  copy:
    dest: <DOSSIER_APP>/<NOM_SCRIPT>.py
    owner: root
    group: root
    mode: '0755'
    content: |
      #!/usr/bin/env python3
      <CONTENU_DU_SCRIPT>
  register: backend_code
```

## Tester sur le serveur

```bash
# lancer à la main (Ctrl+C pour arrêter)
python3 <DOSSIER_APP>/<NOM_SCRIPT>.py

# interroger l'API depuis le serveur
curl -s http://127.0.0.1:<PORT>/

# vérifier sur quelle adresse il écoute (127.0.0.1:<PORT> attendu)
ss -tlnp | grep <PORT>
```

## Variante Node.js (si node est installé)

```javascript
// module HTTP de base de Node
const http = require("http");

// adresse et port d'écoute
const HOST = "<ADRESSE_ECOUTE>";
const PORT = <PORT>;

// fonction appelée à chaque requête
const server = http.createServer((req, res) => {
  // contenu de la réponse
  const body = { "<CLE_1>": "<VALEUR_1>" };
  // code 200 + type JSON
  res.writeHead(200, { "Content-Type": "application/json" });
  // envoie le JSON
  res.end(JSON.stringify(body));
});

// démarre l'écoute
server.listen(PORT, HOST);
```
