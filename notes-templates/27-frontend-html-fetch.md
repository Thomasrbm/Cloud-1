# Frontend : page HTML statique qui appelle une API

- Un seul fichier HTML, pas de build, pas de framework
- Servi par nginx depuis le dossier racine du site
- Le JavaScript appelle l'API par un chemin relatif (`/<CHEMIN_API>/`) → même domaine, pas de souci CORS

## Page : <DOSSIER_SITE>/index.html

```html
<!DOCTYPE html>
<html lang="fr">
<head>
  <!-- encodage des caractères (accents) -->
  <meta charset="utf-8">
  <!-- affichage correct sur mobile -->
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <!-- titre de l'onglet -->
  <title><TITRE_PAGE></title>
</head>
<body>
  <!-- titre visible -->
  <h1><TITRE_PAGE></h1>

  <!-- zone où le message de l'API sera affiché -->
  <p id="<ID_ZONE>">Chargement...</p>

  <script>
    // appelle l'API (chemin relatif = même serveur que la page)
    fetch("/<CHEMIN_API>/")
      // transforme la réponse en objet JavaScript
      .then(function (reponse) { return reponse.json(); })
      // affiche un champ du JSON dans la zone
      .then(function (donnees) {
        document.getElementById("<ID_ZONE>").textContent = donnees.<CLE_A_AFFICHER>;
      })
      // en cas d'erreur (API éteinte, JSON invalide...)
      .catch(function (erreur) {
        document.getElementById("<ID_ZONE>").textContent = "Erreur : " + erreur;
      });
  </script>
</body>
</html>
```

## Tâches Ansible pour la déposer

```yaml
# dossier racine du site (variable, jamais en dur)
- name: Create web root
  file:
    path: "{{ <VARIABLE_DOSSIER_SITE> }}"
    state: directory
    owner: root
    group: root
    mode: '0755'

# dépose la page ; 0644 = lisible par nginx (www-data)
- name: Deploy index.html
  copy:
    dest: "{{ <VARIABLE_DOSSIER_SITE> }}/index.html"
    owner: root
    group: root
    mode: '0644'
    content: |
      <!DOCTYPE html>
      <CONTENU_HTML>
```

- Attention : dans `content:`, un `{{ ... }}` est interprété par Ansible. Si ta page contient des accolades doubles, entoure-les de `{% raw %} ... {% endraw %}`
