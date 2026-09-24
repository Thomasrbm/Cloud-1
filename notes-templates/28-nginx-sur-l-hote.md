# nginx installé directement sur le serveur (apt, sans Docker)

- nginx sert le dossier du site en HTTP
- Il redirige un chemin (`/<CHEMIN_API>/`) vers un programme qui écoute en local
- La config est écrite avec `copy: content:` (pas de templates/)

## Config : /etc/nginx/sites-available/<NOM_SITE>

```nginx
server {
    # écoute le port 80, bloc par défaut si aucun autre ne correspond
    listen 80 default_server;
    # même chose en IPv6
    listen [::]:80 default_server;
    # n'importe quel nom ou IP
    server_name _;

    # dossier des fichiers statiques du site
    root <DOSSIER_SITE>;
    # fichier servi quand on demande "/"
    index index.html;

    # fichiers statiques : sert le fichier s'il existe, sinon 404
    location / {
        try_files $uri $uri/ =404;
    }

    # tout ce qui commence par /<CHEMIN_API>/ part vers le programme local
    location /<CHEMIN_API>/ {
        # "/" final : retire /<CHEMIN_API> avant de transmettre (/<CHEMIN_API>/x -> /x)
        # sans "/" final : le chemin est transmis tel quel
        proxy_pass http://127.0.0.1:<PORT_BACK>/;
        # nom demandé par le visiteur
        proxy_set_header Host $host;
        # vraie IP du visiteur
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Tâches Ansible

```yaml
# installe nginx (le service démarre tout seul après installation sur Debian/Ubuntu)
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: true

# écrit la config du site ; les {{ variables }} remplacent les valeurs en dur
- name: Deploy site config
  copy:
    dest: /etc/nginx/sites-available/<NOM_SITE>
    owner: root
    group: root
    mode: '0644'
    content: |
      server {
          listen 80 default_server;
          listen [::]:80 default_server;
          server_name _;
          root {{ <VARIABLE_DOSSIER_SITE> }};
          index index.html;
          location / {
              try_files $uri $uri/ =404;
          }
          location /<CHEMIN_API>/ {
              proxy_pass http://127.0.0.1:{{ <VARIABLE_PORT_BACK> }}/;
              proxy_set_header Host $host;
          }
      }
  register: nginx_site

# active le site : lien symbolique dans sites-enabled
- name: Enable site
  file:
    src: /etc/nginx/sites-available/<NOM_SITE>
    dest: /etc/nginx/sites-enabled/<NOM_SITE>
    state: link
  register: nginx_link

# supprime le site par défaut (il a aussi "default_server" -> conflit)
- name: Disable default site
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  register: nginx_default

# vérifie la config avant de recharger (évite de casser nginx)
# changed_when false : un test ne modifie rien
- name: Check nginx config
  command: nginx -t
  changed_when: false

# démarré maintenant + au boot
- name: Ensure nginx is running and enabled
  service:
    name: nginx
    state: started
    enabled: true

# recharge seulement si la config a changé (reload = sans couper les connexions)
- name: Reload nginx if config changed
  service:
    name: nginx
    state: reloaded
  when: (nginx_site is changed) or (nginx_link is changed) or (nginx_default is changed)
```

## Où nginx range ses fichiers (Debian/Ubuntu)

- `/etc/nginx/nginx.conf` : config principale (on n'y touche pas)
- `/etc/nginx/sites-available/` : tous les sites déclarés
- `/etc/nginx/sites-enabled/` : liens vers les sites actifs
- `/var/www/html` : dossier par défaut du site
- `/var/log/nginx/access.log` et `error.log` : logs

## Tester

```bash
# syntaxe de la config
nginx -t

# page d'accueil
curl -s http://<IP_SERVEUR>/

# chemin redirigé vers le programme local
curl -s http://<IP_SERVEUR>/<CHEMIN_API>/

# erreurs nginx (ex : 502 Bad Gateway = le programme derrière ne répond pas)
tail -f /var/log/nginx/error.log
```
