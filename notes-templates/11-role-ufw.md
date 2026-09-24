# roles/ufw/tasks/main.yml

- Pare-feu : bloque tout ce qui entre sauf SSH, HTTP, HTTPS
- Module `community.general.ufw` (à mettre dans requirements.yml)

```yaml
---
# installe le pare-feu
- name: Install ufw
  apt:
    name: ufw
    state: present
    update_cache: true

# par défaut, tout ce qui entre est refusé
- name: Default deny incoming
  community.general.ufw:
    direction: incoming
    policy: deny

# le serveur peut sortir sur Internet (mises à jour, images docker)
- name: Default allow outgoing
  community.general.ufw:
    direction: outgoing
    policy: allow

# exceptions ouvertes en TCP
- name: Allow needed ports
  community.general.ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    # SSH : à ouvrir AVANT d'activer le pare-feu, sinon tu perds l'accès
    - "22"
    # HTTP
    - "80"
    # HTTPS
    - "443"
    # autre port si besoin
    # - "<AUTRE_PORT>"

# active le pare-feu
- name: Enable ufw
  community.general.ufw:
    state: enabled
```

```bash
# vérifier l'état et les ports ouverts
sudo ufw status verbose
```
