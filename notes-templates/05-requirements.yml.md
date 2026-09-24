# requirements.yml

## À quoi ça sert

Liste les collections (paquets de modules) à télécharger en plus d'Ansible. Par exemple le module `ufw` ne fait pas partie d'Ansible de base.

## Le fichier

```yaml
---
collections:
  - name: community.general
  - name: ansible.posix
```

## Ligne par ligne

- `collections:` : liste des collections à installer
- `community.general` : collection communautaire, fournit le module `ufw`
- `ansible.posix` : fournit `authorized_key` (clés SSH), `mount` (fstab) et `sysctl`

## Autres collections courantes

```yaml
  - name: community.docker
  - name: <COLLECTION>
    version: "<VERSION>"
```

- `community.docker` : modules pour piloter Docker directement
- `version:` : fixe une version précise

## Installer

```bash
ansible-galaxy collection install -r requirements.yml
```

- Télécharge toutes les collections de la liste.

```bash
ansible-galaxy collection list
```

- Affiche les collections déjà installées.
