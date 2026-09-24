# roles/swap/tasks/main.yml

## À quoi ça sert

Crée un fichier d'échange (swap) sur les petites machines sans swap (ex : AWS t3.micro, 1 Go de RAM). Évite que le système tue un conteneur quand la mémoire est pleine.

## Le fichier

```yaml
---
- name: Configure a swap file
  when:
    - swap_enabled | bool
    - ansible_swaptotal_mb | int == 0
  block:
    - name: Allocate the swap file
      command: "fallocate -l {{ swap_size_mb }}M {{ swap_file }}"
      args:
        creates: "{{ swap_file }}"
      register: swap_allocated

    - name: Restrict the swap file to root
      file:
        path: "{{ swap_file }}"
        owner: root
        group: root
        mode: "0600"

    - name: Format the swap file
      command: "mkswap {{ swap_file }}"
      when: swap_allocated.changed

    - name: Persist in /etc/fstab
      ansible.posix.mount:
        path: none
        src: "{{ swap_file }}"
        fstype: swap
        opts: sw
        state: present

    - name: Enable now
      command: "swapon {{ swap_file }}"
      when: swap_allocated.changed

    - name: Lower swappiness
      ansible.posix.sysctl:
        name: vm.swappiness
        value: "{{ swap_swappiness }}"
        state: present
        sysctl_file: /etc/sysctl.d/99-<NOM_PROJET>-swap.conf
        reload: true
```

## Ligne par ligne

- `when: swap_enabled | bool` : le bloc ne tourne que si activé dans `group_vars/all.yml`
- `ansible_swaptotal_mb | int == 0` : et seulement si le serveur n'a aucun swap. Variable remplie automatiquement par Ansible
- **Allocate the swap file** :
  - `fallocate -l <taille>M` : réserve la place sur le disque d'un coup
  - `creates:` : saute si le fichier existe déjà
  - `register: swap_allocated` : permet de savoir si le fichier vient d'être créé
- **Restrict the swap file to root** : droits `0600` obligatoires, sinon `swapon` refuse (la mémoire pourrait être lue par d'autres)
- **Format the swap file** : `mkswap` prépare le fichier. Seulement s'il vient d'être créé, sinon on casserait un swap actif
- **Persist in /etc/fstab** : ajoute le swap dans `/etc/fstab` pour qu'il revienne après un reboot
  - `path: none` : un swap n'a pas de point de montage
  - `opts: sw` : option standard pour un swap
- **Enable now** : `swapon` active le swap tout de suite, sans reboot
- **Lower swappiness** :
  - `vm.swappiness` : à quel point le système utilise le swap (60 par défaut)
  - `10` : seulement en dernier recours
  - `sysctl_file:` : fichier où le réglage est enregistré pour survivre au reboot
  - `reload: true` : applique le réglage immédiatement

## Vérifier

```bash
swapon --show
```

- Liste les swaps actifs.

```bash
free -h
```

- Affiche la RAM et le swap utilisés.
