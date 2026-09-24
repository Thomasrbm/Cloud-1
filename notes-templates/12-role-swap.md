# roles/swap/tasks/main.yml

- Crée un fichier d'échange sur les petites machines sans swap (ex : AWS t3.micro, 1 Go RAM)
- Évite que le système tue un conteneur quand la mémoire est pleine

```yaml
---
- name: Configure a swap file
  # seulement si activé dans group_vars/all.yml
  # ET si le serveur n'a aucun swap (variable remplie automatiquement par Ansible)
  when:
    - swap_enabled | bool
    - ansible_swaptotal_mb | int == 0
  block:

    # réserve la place sur le disque d'un coup
    # creates: saute si le fichier existe déjà
    # register: permet de savoir si le fichier vient d'être créé
    - name: Allocate the swap file
      command: "fallocate -l {{ swap_size_mb }}M {{ swap_file }}"
      args:
        creates: "{{ swap_file }}"
      register: swap_allocated

    # droits 0600 obligatoires, sinon swapon refuse
    # (la mémoire des programmes pourrait être lue par d'autres utilisateurs)
    - name: Restrict the swap file to root
      file:
        path: "{{ swap_file }}"
        owner: root
        group: root
        mode: "0600"

    # prépare le fichier en swap, seulement s'il vient d'être créé
    # (reformater un swap actif le casserait)
    - name: Format the swap file
      command: "mkswap {{ swap_file }}"
      when: swap_allocated.changed

    # ajoute le swap dans /etc/fstab pour qu'il revienne après un reboot
    # path: none = un swap n'a pas de point de montage / opts: sw = option standard
    - name: Persist in /etc/fstab
      ansible.posix.mount:
        path: none
        src: "{{ swap_file }}"
        fstype: swap
        opts: sw
        state: present

    # active le swap tout de suite, sans reboot
    - name: Enable now
      command: "swapon {{ swap_file }}"
      when: swap_allocated.changed

    # vm.swappiness : à quel point le système utilise le swap (60 par défaut, 10 = dernier recours)
    # sysctl_file : fichier où le réglage est enregistré pour survivre au reboot
    # reload : applique immédiatement
    - name: Lower swappiness
      ansible.posix.sysctl:
        name: vm.swappiness
        value: "{{ swap_swappiness }}"
        state: present
        sysctl_file: /etc/sysctl.d/99-<NOM_PROJET>-swap.conf
        reload: true
```

```bash
# liste les swaps actifs
swapon --show

# RAM et swap utilisés
free -h
```
