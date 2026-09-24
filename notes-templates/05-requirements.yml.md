# requirements.yml

- Collections (paquets de modules) à télécharger en plus d'Ansible de base

```yaml
---
collections:
  # fournit le module ufw (pare-feu)
  - name: community.general

  # fournit authorized_key (clés SSH), mount (fstab), sysctl
  - name: ansible.posix

  # (facultatif) modules pour piloter Docker directement
  # - name: community.docker

  # (facultatif) fixer une version précise
  # - name: <COLLECTION>
  #   version: "<VERSION>"
```

```bash
# installe toutes les collections de la liste
ansible-galaxy collection install -r requirements.yml

# affiche les collections déjà installées
ansible-galaxy collection list
```
