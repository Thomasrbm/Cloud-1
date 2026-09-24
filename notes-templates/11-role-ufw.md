# roles/ufw/tasks/main.yml

## À quoi ça sert

Pare-feu : bloque toutes les connexions entrantes sauf SSH, HTTP et HTTPS.

## Le fichier

```yaml
---
- name: Install ufw
  apt:
    name: ufw
    state: present
    update_cache: true

- name: Default deny incoming
  community.general.ufw:
    direction: incoming
    policy: deny

- name: Default allow outgoing
  community.general.ufw:
    direction: outgoing
    policy: allow

- name: Allow needed ports
  community.general.ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - "22"
    - "80"
    - "443"

- name: Enable ufw
  community.general.ufw:
    state: enabled
```

## Tâche par tâche

- **Install ufw** : installe le pare-feu
- **Default deny incoming** : par défaut, tout ce qui entre est refusé
- **Default allow outgoing** : le serveur peut sortir sur Internet (mises à jour, images docker)
- **Allow needed ports** : exceptions ouvertes en TCP
  - `22` : SSH, à ouvrir AVANT d'activer le pare-feu sinon tu perds l'accès
  - `80` : HTTP
  - `443` : HTTPS
  - Ajoute `"<AUTRE_PORT>"` dans la liste si besoin
- **Enable ufw** : active le pare-feu
- `community.general.ufw` : module de la collection `community.general`, à mettre dans `requirements.yml`

## Vérifier

```bash
sudo ufw status verbose
```

- Affiche l'état du pare-feu et la liste des ports ouverts.
