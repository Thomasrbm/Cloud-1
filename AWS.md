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
- AMI : **Ubuntu Server 24.04 LTS** (ou 22.04) — `x86_64`
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

Secrets (une seule fois) :

```sh
cp group_vars/webservers.yml.example group_vars/webservers.yml
$EDITOR group_vars/webservers.yml          # mets tes vrais mots de passe
ansible-vault encrypt group_vars/webservers.yml
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
