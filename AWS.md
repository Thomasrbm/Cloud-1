# Héberger Cloud-1 sur AWS (EC2)

Le playbook ne change pas : il lui faut juste une machine Ubuntu joignable en SSH.
On remplace donc le VPS Hostinger par une instance **EC2**.

---

## 1. Créer la paire de clés SSH (console AWS)

EC2 > Réseau et sécurité > **Paires de clés** > Créer une paire de clés
- Nom : `cloud1-aws`
- Type : **ED25519** (ou RSA)
- Format : **.pem**

Le fichier se télécharge une seule fois. Sur ta machine :

```sh
mv ~/Téléchargements/cloud1-aws.pem ~/.ssh/
chmod 400 ~/.ssh/cloud1-aws.pem
```

## 2. Créer le groupe de sécurité (le pare-feu AWS)

EC2 > Réseau et sécurité > **Groupes de sécurité** > Créer
- Nom : `cloud1-sg`
- Règles **entrantes** :

| Type  | Port | Source |
|-------|------|--------|
| SSH   | 22   | **Mon IP** (recommandé) |
| HTTP  | 80   | 0.0.0.0/0 |
| HTTPS | 443  | 0.0.0.0/0 |

- Règles sortantes : laisser tout autorisé.

> UFW (rôle `ufw`) applique les mêmes règles *dans* la machine : les deux doivent
> être ouverts, sinon la connexion est bloquée.

## 3. Lancer l'instance

EC2 > Instances > **Lancer une instance**
- Nom : `cloud1`
- AMI : **Ubuntu Server 22.04 LTS** — `x86_64`
  - le sujet impose « an Ubuntu 22.04 LTS-like OS » : on prend la version exacte
  - elle n'est pas dans l'onglet *Démarrage rapide* → **Parcourir d'autres AMI**,
    chercher `ubuntu 22.04`, onglet **AMI communautaires**, éditeur *Canonical*
  - le rôle `docker` détecte la version seule (`ansible_distribution_release`),
    donc 24.04 ou 26.04 fonctionnent aussi — mais 22.04 est ce que le sujet demande
- Type : **t3.micro** (2 vCPU / 1 Go, largement suffisant)
- Paire de clés : `cloud1-aws`
- Paramètres réseau : *Sélectionner un groupe de sécurité existant* > `cloud1-sg`
- Stockage : **20 Gio gp3** (les images Docker + MySQL tiennent large)
- Lancer.

## 4. Fixer l'IP (Elastic IP) — optionnel mais conseillé

Sans ça, l'IP publique change à chaque stop/start de l'instance.

EC2 > Réseau et sécurité > **Adresses IP Elastic** > Allouer, puis
*Actions > Associer* à l'instance `cloud1`.

> Gratuit **tant qu'elle est associée à une instance démarrée**, facturée sinon :
> ne pas laisser d'Elastic IP orpheline.

## 5. Vérifier la connexion SSH

```sh
ssh -i ~/.ssh/cloud1-aws.pem ubuntu@<IP_PUBLIQUE>
```

L'utilisateur est **`ubuntu`**, pas `root` (AWS interdit le login root direct ;
le playbook passe root via `become: true`, qui utilise le sudo sans mot de passe
déjà configuré sur l'AMI).

## 6. Configurer le projet

`inventory.ini` :

```ini
[webservers]
server1 ansible_host=<IP_PUBLIQUE> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/cloud1-aws.pem
```

Secrets : rien a faire. `group_vars/webservers.yml` est deja dans le depot,
chiffre par ansible-vault ; `--ask-vault-pass` le dechiffre en memoire au
deploiement. Uniquement pour repartir de zero avec de nouveaux mots de passe :

```sh
cp group_vars/webservers.yml.example group_vars/webservers.yml
$EDITOR group_vars/webservers.yml          # mets tes vrais mots de passe
ansible-vault encrypt group_vars/webservers.yml   # obligatoire avant de committer
```

Dépendances Ansible :

```sh
ansible-galaxy collection install -r requirements.yml
```

## 7. Déployer

```sh
ansible -m ping webservers                 # test de connexion
ansible-playbook playbook.yml --ask-vault-pass
```

Puis dans le navigateur :
- WordPress  : `https://<IP_PUBLIQUE>/`
- phpMyAdmin : `https://<IP_PUBLIQUE>/phpmyadmin/`

Le certificat est auto-signé → l'avertissement du navigateur est normal
(« Avancé » > « Continuer »).

---

## Coûts / crédits

Compte free plan : **100 $ de crédits**, valables jusqu'à épuisement ou fin de période.

Estimation en `eu-north-1` (Stockholm) pour une `t3.micro` allumée 24/7 :

| Poste | ~ coût / mois |
|-------|---------------|
| t3.micro (~0,0108 $/h) | ~8 $ |
| EBS gp3 20 Gio | ~1,6 $ |
| Trafic sortant (projet école) | ~0 $ |
| **Total** | **~10 $/mois** |

Les crédits tiennent donc largement la durée du projet. Réflexes :
- **Stopper l'instance** quand tu ne bosses pas (l'EBS reste facturé, le calcul non) ;
- Budgets > **créer une alerte** à 20 $ pour ne pas se faire surprendre ;
- à la fin du projet : *Terminer* l'instance, **libérer l'Elastic IP**, supprimer le volume EBS.

## Dépannage

| Symptôme | Cause probable |
|----------|----------------|
| `Permission denied (publickey)` | mauvais user (`ubuntu`, pas `root`) ou `chmod 400` manquant sur le .pem |
| SSH qui timeout | port 22 non ouvert dans le groupe de sécurité, ou IP source changée |
| Site injoignable mais SSH OK | 80/443 absents du groupe de sécurité (UFW seul ne suffit pas) |
| `ansible-galaxy`/module `ufw` introuvable | `ansible-galaxy collection install -r requirements.yml` oublié |
| Bloqué sur `Gathering Facts` alors que `ssh` manuel passe | socket SSH multiplexé figé : `rm -rf ~/.ansible/cp` |
| Déploiement très lent, conteneurs tués au hasard | RAM saturée : vérifie `free -m` (le rôle `swap` couvre ce cas) |

---

## Travailler depuis plusieurs machines (PC fixe, portable, poste 42)

La clé `.pem` AWS n'est téléchargeable **qu'une fois** et n'est injectée dans
l'instance qu'**au lancement**. Plutôt que de recopier cette clé privée partout
(un seul secret partagé = tout à refaire si une machine est compromise), chaque
machine garde **sa propre clé**, et on ajoute sa clé **publique** au serveur.

### Sur une nouvelle machine

```sh
ssh-keygen -t ed25519 -C "portable"     # si pas déjà de clé
cat ~/.ssh/id_ed25519.pub
```

- Colle la ligne dans `roles/ssh_access/files/<machine>.pub` (ex. `portable.pub`)
- Commit + push
- Relance le playbook **depuis une machine déjà autorisée** :
  `ansible-playbook playbook.yml --ask-vault-pass`
- Le rôle `ssh_access` ajoute la clé dans `~/.ssh/authorized_keys` de `ubuntu` :
  la nouvelle machine peut désormais se connecter **sans le `.pem`**.

Sur cette nouvelle machine, `inventory.ini` devient simplement :

```ini
server1 ansible_host=<IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

### Cas particulier : poste de l'école

- Ne stocke pas de clé privée durable sur un poste partagé.
- Solution sans aucune clé locale : console AWS > EC2 > l'instance >
  **Se connecter** > onglet **EC2 Instance Connect** → terminal SSH dans le navigateur.

### Rattrapage : `.pem` perdu et aucune autre clé autorisée

L'instance n'est alors plus joignable en SSH. Deux issues :
- **EC2 Instance Connect** depuis la console (si le port 22 accepte les plages AWS) ;
- sinon relancer une instance neuve avec une nouvelle paire de clés et rejouer
  le playbook (rien n'est perdu : tout est décrit dans le dépôt).

### WSL : où atterrit le `.pem` ?

Le navigateur tourne sous Windows, donc le fichier est dans le `Downloads`
Windows, visible depuis WSL via `/mnt/c` :

```sh
ls /mnt/c/Users/*/Downloads/cloud1-aws.pem
cp /mnt/c/Users/<TonUser>/Downloads/cloud1-aws.pem ~/.ssh/
chmod 400 ~/.ssh/cloud1-aws.pem
```

Toujours copier la clé dans le système de fichiers **Linux** (`~/.ssh`) : sur
`/mnt/c`, `chmod 400` ne tient pas et `ssh` refuse la clé
(*permissions are too open*).

---

## Rejouer la démo devant un correcteur

`teardown.yml` remet le serveur à zéro pour redémontrer le déploiement autant de
fois que nécessaire.

### Niveau 1 — stack + données (~1 min de redéploiement)

```sh
ansible-playbook teardown.yml
```

Supprime conteneurs, images, réseaux et **toutes** les données
(`/opt/wordpress` : site, base MySQL, certificats). Docker reste installé.

### Niveau 2 — désinstallation totale (démo intégrale)

```sh
ansible-playbook teardown.yml -e full_wipe=true
```

En plus : désinstalle Docker, son dépôt apt, sa clé GPG, `/var/lib/docker`, et
réinitialise UFW. Le serveur redevient un **Ubuntu nu** → le correcteur voit le
playbook tout réinstaller de zéro.

### Boucle de démonstration

```sh
ansible-playbook teardown.yml -e full_wipe=true      # tape "oui" à la confirmation
ansible-playbook playbook.yml --ask-vault-pass       # tout se réinstalle
# puis https://<IP>/ et https://<IP>/phpmyadmin/
```

Pour enchaîner sans confirmation interactive :

```sh
ansible-playbook teardown.yml -e full_wipe=true -e confirm=oui
```

### Garde-fous intégrés

- confirmation `oui` obligatoire (sautée seulement si `-e confirm=oui`) ;
- refus de supprimer un `project_dir` suspect (`/`, `/etc`, `/home`, chemin trop court…) ;
- fonctionne même si Docker est déjà absent (tâches conditionnées, pas d'erreur) ;
- **idempotent** : relancer le teardown sur un serveur déjà propre ne casse rien.

> Le teardown ne touche ni à l'instance EC2, ni à ton `inventory.ini`, ni aux clés
> SSH autorisées : seule l'application est détruite.

---

## Connexion root (exigence de soutenance)

> *« The student must connect as root using their email address or login as the
> root account. »*

Les images cloud bloquent volontairement le compte root : la clé est bien dans
`/root/.ssh/authorized_keys`, mais précédée d'un
`command="echo 'Please login as the user \"ubuntu\"'"` qui coupe la session.

Le rôle `ssh_access` lève ce blocage au premier déploiement :

- copie les clés publiques autorisées dans `/root/.ssh/authorized_keys` ;
- retire la commande forcée de l'image cloud ;
- force `PermitRootLogin prohibit-password` (**clé uniquement, jamais de mot de
  passe**), y compris dans les fichiers `/etc/ssh/sshd_config.d/*.conf` qui
  écrasent parfois le réglage principal ;
- recharge sshd **sans couper** les sessions en cours.

```sh
ssh -i ~/.ssh/cloud1-aws.pem root@<IP_PUBLIQUE>
```

Désactivable si besoin : `allow_root_ssh: false` dans `group_vars/all.yml`.

⚠️ Le tout premier `ansible-playbook` se fait forcément avec `ansible_user=ubuntu`
(root est encore bloqué). Ensuite, tu peux basculer l'inventaire sur
`ansible_user=root` si tu préfères.
