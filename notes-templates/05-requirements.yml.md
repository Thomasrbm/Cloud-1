# requirements.yml

```yaml
---
# Installe avec : ansible-galaxy collection install -r requirements.yml
collections:
  - name: community.general   # ufw, etc.
  - name: ansible.posix       # authorized_key, mount, sysctl
  # - name: community.docker  # docker_container, docker_compose_v2
  # - name: <COLLECTION>
  #   version: "<VERSION>"

# roles:
#   - name: <AUTEUR>.<ROLE>
```

## Commandes

```sh
ansible-galaxy collection install -r requirements.yml
ansible-galaxy collection list
```
