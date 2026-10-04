# 5/ LEXIQUE

## Sommaire

- **Sécurité & accès** : [Bastion d'administration](#bastion-dadministration-pam) · [ZED!](#zed-zone-centrale) · [KeePass](#keepass) · [Keycloak](#keycloak) · [AppArmor / SELinux](#apparmor-debian--selinux-rhel) · [Headscale](#headscale) · [Service de signature](#service-de-signature-électronique)
- **Logs & supervision** : [Syslog](#syslog-system-logging-protocol) · [Puits de logs](#puits-de-logs) · [node exporter](#node-exporter) · [cAdvisor](#cadvisor)
- **Réseau** : [NTP](#ntp-network-time-protocol) · [MPLS](#mpls) · [Topologie mesh VXLAN](#topologie-mesh-vxlan) · [DNS](#dns) · [FQDN](#fqdn) · [Domaine de broadcast](#domaine-de-broadcast) · [IEEE 802](#ieee-802) · [Bond0 LACP](#bond0-lacp) · [Tunnel inverse](#tunnel-inverse-reverse-tunnel) · [vhost](#vhost-plusieurs-sites-sur-une-même-machine) · [VIP](#vip-ip-virtuelle) · [Stub systemd-resolved](#stub-systemd-resolved) · [rpcbind](#rpcbind) · [Loopback](#loopback) · [Caddy](#caddy-termine-tls-et-proxifie)
- **Stockage & infra** : [SPOF](#spof) · [HA](#ha-haute-disponibilité) · [Redondance](#redondance) · [RAID](#raid-redundant-array-of-independent-disks) · [Ceph](#ceph) · [Disque MON](#disque-mon-moniteur-ceph) · [Volumes Cinder](#volumes-cinder) · [Overcommit RAM](#surallocation-de-ram-overcommit) · [HCI](#informatique-hyperconvergée-hci) · [HCI vs Ceph](#différence-hyperconvergé-vs-ceph) · [Garage](#garage) · [Rack](#rack) · [Plateforme](#plateforme)
- **Outils & dev** : [FreeFileSync](#freefilesync) · [HashCalc](#hashcalc) · [LDAP](#format-ldap) · [Bundler Sandpack](#bundler-sandpack) · [Shim Python](#shim-python) · [Watchtower](#watchtower) · [Bifrost](#bifrost) · [pgx](#pgx-docs) · [« Par digest »](#par-digest) · [Base vectorielle](#base-vectorielle-vectordb) · [Meilisearch](#meilisearch) · [CUPS](#cups)

---

## Bastion d'administration (PAM)

> **PAM** = *Privileged Access Management* (gestion des accès à privilèges)

Système ultra sécurisé qui sert de point de passage **UNIQUE** pour toutes les connexions d'administration sensibles (serveurs, bases de données, pare-feu, réseaux). Exemple : **WALLIX**.

**Lien avec le Zero Trust ?**

- Probablement, car il applique le principe du **moindre privilège**.
- **Traçabilité et audit** : chaque session est enregistrée.
- **MFA** (authentification multifacteur) imposée.
- Il pilote la **rotation des mots de passe**.

➡️ Exigé / recommandé pour la certification **ISO 27001**, le **RGPD**, **NIS2** et les recommandations de l'**ANSSI**.

**Particularités de WALLIX** : leader du marché, solution française.

---

## Syslog (System Logging Protocol)

Protocole pour envoyer / partager les logs à travers les systèmes de ton infra et **centraliser** les rapports d'événements.

---

## ZED! (Zone centrale)

- Chiffrement des données des postes de travail.
- Fonctionne comme un **coffre-fort** (*vault*) chiffré.
- Le chiffrement se fait **directement sur les postes**.

---

## KeePass

Gestionnaire de mots de passe (libre).

---

## FreeFileSync

Synchronisation de fichiers entre plusieurs appareils, disques durs ou services cloud (logiciel libre).

---

## HashCalc

Outil gratuit pour calculer des **sommes de contrôle** (*checksums* : MD5, SHA-1…) et vérifier l'intégrité d'un fichier.

---

## NTP (Network Time Protocol)

Protocole pour **synchroniser l'heure** entre toutes les machines (essentiel pour la cohérence des logs, l'authentification, etc.).

---

## MPLS

Sorte de **réseau privé** dédié à chaque grand groupe (un peu comme un VXLAN privé) : il permet de **garantir le débit et la bande passante** pour le groupe.

Utilisé par les opérateurs car plus simple à gérer pour eux, mais pas forcément pour les entreprises.

---

## Service de signature électronique

Signature électronique, horodatage et cachetage des documents électroniques, avec une fiabilité **équivalente à une signature manuscrite**.

---

## SPOF

**SPOF** = *Single Point of Failure* (point de défaillance unique) : tout composant dont la panne peut **arrêter l'ensemble du système**.

---

## HA (Haute disponibilité)

> *High Availability*

Si un service tombe, il est **remonté automatiquement et immédiatement** (bascule sur un autre nœud).

---

## Disque MON (moniteur Ceph)

Dans un cluster **Ceph**, le **moniteur (MON)** est le « maître » qui gère tous les autres et s'assure de la **pérennité du système et des données** (il maintient la carte du cluster).

---

## Volumes Cinder

Les volumes de stockage en mode bloc d'**OpenStack** (Cinder est le service de stockage bloc d'OpenStack).

---

## Surallocation de RAM (overcommit)

Tu promets à plusieurs machines plus de RAM que ce que ton serveur possède réellement. Tu **paries** sur le fait qu'elles ne vont jamais toutes demander le maximum en même temps.

**Exemple** : tu as 24 Go et tu donnes 12 Go à chacune de 3 VM (36 Go promis).
Tu paries que toutes seront à 8 Go max en même temps, voire souvent bien moins, et que si une a besoin de 12 Go, les deux autres auront besoin de moins au même moment.

---

## Topologie mesh VXLAN

Chaque point d'extrémité de tunnel VXLAN (**VTEP**) établit une communication **directe** avec tous les autres VTEP.
Aucun contrôleur central n'est nécessaire pour le routage entre les points d'extrémité : le réseau est entièrement interconnecté sur le plan logique (maillage complet).

**Avantages :**

- **Connectivité simplifiée** : chaque point d'extrémité peut communiquer directement avec n'importe quel autre.
- **Haute disponibilité** : aucun point de défaillance unique en cas de panne d'un point d'extrémité.
- **Faible latence** : transfert direct via le chemin le plus court dans le réseau sous-jacent.

---

## Informatique hyperconvergée (HCI)

Approche **pilotée par logiciel** qui combine virtualisation et gestion des ressources.

- On regroupe le **stockage**, la **puissance de calcul (CPU/GPU)** et la **RAM** de tous les nœuds, puis on les attribue selon les besoins (répartition de charge / *load balancing*).
- On **centralise** la gestion du réseau, du stockage et de la puissance.
- OpenStack n'a pas cette approche nativement : il faut y ajouter **Ceph** (stockage) et **Masakari** (haute disponibilité des instances).

---

## Différence hyperconvergé vs Ceph

- **Ceph** : uniquement du **stockage distribué**.
- **Hyperconvergé** : stockage **+** réseau **+** puissance de calcul. Ceph peut en faire partie.

---

## Format LDAP

> *Lightweight Directory Access Protocol* : protocole d'accès à un annuaire.

- Une base de données d'**utilisateurs** et de **groupes**.
- Une structure en **arborescence**.
- Et surtout des **règles** pour contrôler l'accès aux données.

---

## Rack

Structure ou armoire conçue pour accueillir et organiser du matériel (serveurs, switchs…).

---

## Plateforme

Environnement qui permet d'exécuter des logiciels ou de développer des applications.

---

## DNS

Serveur qui s'occupe de faire la **traduction entre nom de domaine et adresse IP**.

---

## Domaine de broadcast

Ensemble des appareils d'un réseau local qui reçoivent les messages envoyés en **diffusion** (*broadcast*), c'est-à-dire à tous les appareils du réseau.

- On peut le découper avec des **VLAN**, des réseaux privés, etc.
- Le **routeur** permet de faire communiquer ces domaines entre eux (il ne transmet pas les broadcasts).

---

## FQDN

**FQDN** = *Fully Qualified Domain Name*, soit **nom de domaine pleinement qualifié** : le nom complet d'une machine, ex. `serveur1.exemple.fr.`

---

## IEEE 802

L'**IEEE** est une organisation à but non lucratif qui crée des **normes** pour que tout le monde puisse utiliser les mêmes technologies.
**802** = grand projet de normes réseau : **80** pour 1980 et **2** pour février.

| Norme | Description |
|---|---|
| **802.1** | Architecture de gestion des réseaux, pontage (*bridging*), VLAN et sécurité globale (couches hautes des LAN) |
| **802.2** | Sous-couche LLC (*Logical Link Control*), commune à la plupart des réseaux locaux |
| **802.3** | Ethernet pour les réseaux locaux câblés (cuivre et fibre) |
| **802.4** | Réseau à jeton sur bus (*Token Bus*), aujourd'hui retiré |
| **802.5** | Réseau en anneau à jeton (*Token Ring*), développé par IBM |
| **802.11** | Réseaux locaux sans fil (Wi-Fi) |
| **802.15** | Réseaux personnels sans fil (WPAN) : Bluetooth, ZigBee |
| **802.16** | Accès métropolitain sans fil (WiMAX) |
| **802.22** | Réseaux régionaux sans fil utilisant les espaces blancs hertziens (WRAN) |

- Lettres **MAJUSCULES** = norme principale (ex. **802.1Q** = VLAN).
- Lettres **minuscules** = amendements (ex. **802.11a**, **802.11ax** = Wi-Fi 6, Wi-Fi moderne).

---

## Bundler Sandpack

L'équivalent d'un environnement d'exécution côté serveur, mais **côté client, dans le navigateur**.

- Utilise des **Web Workers**.
- Exécute (et empaquette) le JS, etc., directement dans le navigateur.

---

## Bond0 LACP

> Agrégation de liens Linux en LACP (*mode 4 / 802.3ad*)

Permet d'associer **plusieurs interfaces réseau physiques** en une seule interface logique nommée `bond0`, pour **augmenter le débit** et assurer une **tolérance aux pannes**.

➡️ C'est de la **parallélisation d'interfaces réseau**.

---

## Tunnel inverse (reverse tunnel)

**Situation :**

- On a un site en local sur le port `8080`.
- On a un VPS avec l'IP publique `203.0.113.42`.
- On veut voir le site via `203.0.113.42:9000`, alors que le site n'est **pas** hébergé sur le VPS.

```bash
ssh -R 9000:localhost:8080 user@203.0.113.42
```

**Ce qui se passe techniquement :**

1. Ta machine locale ouvre une connexion SSH sécurisée vers le serveur public.
2. Le serveur public ouvre le port `9000` sur sa propre interface.
3. Toute personne qui se connecte au serveur public sur le port 9000 (ex. `http://203.0.113.42:9000`) est automatiquement redirigée, à travers le tunnel, vers le port `8080` de ta machine locale.

---

## node exporter

Expose des **métriques** (pas des logs) de consommation : CPU, RAM, stockage, température des composants, vitesse des ventilateurs, etc.
Format standardisé pour être lu par **Prometheus** (format OpenMetrics).

- ➡️ **Prometheus** pour **stocker** tous ces chiffres, car node exporter et cAdvisor n'ont **pas d'historique** : ils fournissent juste les données dans un format propre.
- ➡️ **Grafana** pour **afficher** tout ça.

---

## cAdvisor

Comme **node exporter**, mais pour les **conteneurs**.

---

## Shim Python

**pyenv** utilise des *shims* : de petits exécutables qui viennent encapsuler ta commande / ton script Python pour l'exécuter avec la **bonne version** de Python.

---

## Watchtower

Outil open source, un peu dans l'esprit GitOps comme **ArgoCD** (qui lui est uniquement pour Kubernetes) ; ici c'est pour **Docker**.
Il **surveille les registres d'images** et met à jour automatiquement les conteneurs quand une nouvelle image est publiée.

---

## Redondance

- **Redondance fonctionnelle** : plusieurs composants capables d'exécuter la même fonction.
- **Redondance des données** : plusieurs copies des mêmes données, en miroir ou réparties sur différents serveurs.
- **Redondance géographique** : copies réparties sur différents centres ou sites, pour se protéger des défaillances locales ou régionales.

---

## Bifrost

**Passerelle API** pour piloter tout type d'IA.

- **100 % compatible** avec le format d'API d'OpenAI : on peut **changer de modèle** simplement.
- **Tolérance aux pannes** (*failover*).
- **Vitesse extrême** (écrit en Go).
- **Cache sémantique** : si deux utilisateurs posent une question similaire (ex. « Quel temps fait-il ? » et « Donne-moi la météo »), Bifrost comprend le sens commun, récupère la réponse déjà stockée en mémoire et évite de repayer le fournisseur d'IA.
- **Gestion budgétaire** : suivi des coûts en temps réel, limites financières, création de clés virtuelles pour tes équipes ou tes clients.
- Une **interface web** permet de tout gérer.

---

## pgx (docs)

Bibliothèque qui permet à un programme en **Go** de communiquer directement avec une base **PostgreSQL**.

---

## Keycloak

Service de gestion des identités qui fournit :

- Le **SSO** (authentification unique).
- **OAuth** / OpenID Connect, connexion en un clic avec Google, etc.
- La **MFA** (SMS, mail, etc.).
- Le contrôle du **consentement** : « Autorisez-vous cette application à accéder à vos données ? »

- Il y a un **realm `master`** réservé à l'administration.
- Une **console web** permet de gérer les comptes, leurs informations et les méthodes d'authentification.

---

## « Par digest »

Signifie **par empreinte (hash)** : ex. une image Docker référencée par son hash `sha256:…` plutôt que par son tag.

---

## Garage

Sert à stocker de grandes quantités de fichiers (images, vidéos, documents, sauvegardes) de manière sécurisée et **décentralisée**.
Il remplace les services de stockage cloud propriétaires (comme **Amazon S3** ou Google Cloud Storage — il est compatible S3) mais s'installe sur **tes propres serveurs**.

1. **Découpage** : Garage prend ton fichier et le découpe en petits morceaux (**blocs**).
2. **Répartition** : il attribue un identifiant unique à chaque morceau grâce à une **table de hachage distribuée (DHT)**. Cette table sert de « plan » pour savoir quel morceau doit aller sur quel serveur, **sans serveur central**.
3. **Réplication automatique** : par défaut, Garage copie chaque morceau sur **3 serveurs différents**.

---

## Base vectorielle (vectordb)

Base de données qui stocke des **vecteurs** (*embeddings*), souvent utilisée pour l'**IA** (recherche par similarité de sens).

---

## Meilisearch

Moteur de recherche **open source** écrit en **Rust**, ultra rapide.
Spécialité : la recherche **instantanée au fil de la frappe** (*search-as-you-type*).

---

## vhost (plusieurs sites sur une même machine)

De base, on a un site à la racine `/` et éventuellement des sous-sites dans des sous-dossiers, mais ils restent liés d'une certaine manière.

Si on veut **plusieurs racines `/`** avec des sites différents, il faut des **hôtes virtuels (vhosts)**, qui permettent de les servir sur le **même serveur** :

- **Par nom** (*name-based*) : plusieurs noms de domaine pointent vers une seule adresse IP ; le serveur trie selon le nom demandé.
- **Isolation** : chaque site possède sa propre configuration, son propre dossier racine et ses propres paramètres, sans interférer avec les autres.

---

## VIP (IP virtuelle)

**Une seule adresse IP partagée par plusieurs machines** : si une machine tombe, une autre reprend l'IP (utilisé pour la haute disponibilité, ex. keepalived).

---

## Stub systemd-resolved

Le *stub resolver* de **systemd-resolved** est un **serveur DNS local minimaliste** qui tourne en tâche de fond sur l'interface de bouclage (*loopback*) de Linux (`127.0.0.53`, port **53**).

---

## rpcbind

Un **aiguilleur réseau** pour les applications Linux (utilisé notamment par **NFS**).
Son rôle est de mettre en relation un client et un serveur pour certains services spécifiques, comme le partage de fichiers en réseau.

Exemple de ce que dit un service à rpcbind :
> « Je viens de démarrer. Je me suis attribué le port TCP 4001 au hasard. Enregistre dans ta table que mon identifiant (programme RPC) correspond au port 4001. »

Le client demande ensuite à rpcbind (port 111) sur quel port joindre ce service.

---

## CUPS

> *Common Unix Printing System*

Serveur d'impression **modulaire et open source** : le **chef d'orchestre** entre ton ordinateur et tes imprimantes.

---

## Loopback

Signifie « en **localhost** », sur l'interface `lo` (`127.0.0.1`) : le trafic ne sort pas de la machine.

---

## Headscale

Implémentation **open source et auto-hébergée** du serveur de coordination de **Tailscale**.
En gros, c'est du **WireGuard** (VPN maillé) géré par ton propre serveur.

---

## AppArmor (Debian) / SELinux (RHEL)

Ils **enferment chaque programme dans une cage** et surveillent ce à quoi il accède.
Exemple : ils interdisent à ton serveur web d'aller fouiller dans tes mots de passe système ou tes clés SSH.

#### 🟢 AppArmor

- **Approche** : basée sur les chemins d'accès des fichiers (`/etc/apparmor.d/`)
- **Complexité** : plus simple, prise en main rapide
- **Granularité** : bonne pour la protection des applications
- **Poids / performance** : très léger, impact minimal sur les ressources
- **Distributions par défaut** : Ubuntu, Debian, openSUSE

#### 🔴 SELinux (*Security-Enhanced Linux*)

- **Approche** : basée sur des étiquettes de sécurité (*labels*, liées aux inodes)
- **Complexité** : courbe d'apprentissage abrupte, très complexe
- **Granularité** : très fine, multi-niveaux (MLS / RBAC)
- **Poids / performance** : légèrement plus lourd
- **Distributions par défaut** : RHEL, CentOS, Fedora, AlmaLinux, Rocky Linux

---

## Puits de logs

Architecture **centralisée** qui collecte, normalise et stocke l'ensemble des journaux d'activité (logs) d'un système d'information en **un point unique**.
Il peut alimenter un **SIEM** (outil d'analyse et de détection d'incidents de sécurité).

---

## Caddy termine TLS et proxifie

- **Termine TLS** : Caddy gère la sécurité et le chiffrement (HTTPS) — il déchiffre le trafic à l'entrée. (TLS est le successeur de SSL.)
- **Proxifie** (*reverse proxy*) : Caddy transmet ensuite la requête à ton application.

---

## RAID (Redundant Array of Independent Disks)

Différents niveaux de gestion de plusieurs disques de stockage ensemble.

**Matériel vs logiciel :**

- **RAID matériel** : une carte dédiée fait le travail.
- **RAID logiciel** : consomme du CPU et de la RAM, mais compatible avec plus d'OS, moins cher en matériel, et on peut changer de matériel facilement.

### Les niveaux essentiels

| Niveau | Disques min. | Principe |
|---|---|---|
| **RAID 0** | 2 | **Performances** : les données sont découpées (*striping*) et écrites en parallèle sur plusieurs disques (lecture/écriture simultanées). **Aucune redondance.** |
| **RAID 1** | 2 | **Miroir** (*mirroring*) : chaque disque a son clone. |
| **RAID 5** | 3 | **Parité simple** (algo **XOR**) répartie sur les disques : permet de reconstruire **1** disque perdu. Si le disque 1 tombe, on le retrouve grâce à disque 2 + parité (`D1 = D2 XOR P`). |
| **RAID 6** | 4 | **Double parité** : une parité **P** (comme le RAID 5) + une parité **Q** (algo **Reed-Solomon**). On peut perdre **2** disques en même temps et tout reconstruire. On peut aussi reformer P ou Q à partir des disques de données. |
| **RAID 10** | 4 | Combine **1 + 0** : on clone par paires (miroir) **puis** on répartit (*striping*). Seulement **50 %** de la capacité totale est utilisable. Ex. : on écrit les blocs A et B → A sur le disque 1, B sur le disque 2, et leurs clones A sur le 3, B sur le 4. |
| **RAID 50** | 6 | Combine **5 + 0** : plusieurs groupes RAID 5 sur lesquels on fait du striping. |

- On choisit selon la **complexité** qu'on veut gérer (plus il y a de disques, plus c'est dur) et le **nombre de disques disponibles**.
- Il existe aussi des RAID **hybrides (imbriqués)** et des alternatives (ZFS, etc.).
- **Rarement combiné avec Ceph** : ça ajoute une complexité inutile, puisque Ceph gère déjà la redondance.

---

## Ceph

Solution **logicielle open source de stockage distribué**.

- Redondance non seulement **locale** mais **à l'échelle de tout le cluster**.
- Architecture entièrement distribuée : **SANS POINT DE DÉFAILLANCE UNIQUE !**

### Principaux composants

- **Moniteur (MON)** : assure la cohérence du cluster en maintenant une carte à jour (*cluster map*).
- **Démon OSD** (*Object Storage Daemon*) : un peu comme le *kubelet*, il gère le stockage réel des données sur les disques, assure la réplication et la récupération automatique. Chaque disque (ou partition) a le sien.
- **MDS** (*Metadata Server*) : gère les métadonnées pour l'interface système de fichiers (CephFS).
- **CRUSH** : algorithme qui détermine automatiquement où doit être stockée chaque donnée.
- **Réplication et tolérance** : les données sont répliquées sur plusieurs OSD.
- **RADOS** : couche de stockage objet ; on accède aux objets via des bibliothèques et des API pour les applications cloud (ex. RADOS Gateway compatible S3).
- **RBD** (*RADOS Block Device*) : crée des volumes de stockage utilisables comme disques virtuels, adaptés aux machines virtuelles ou aux bases de données.
- **CephFS** : système de fichiers compatible **POSIX** (exportable en NFS).

### Points forts

- **Scalabilité horizontale** : évolue en ajoutant des OSD ou des moniteurs **sans interrompre** les services.
- **Autogestion** : le cluster détecte automatiquement les pannes et rééquilibre les données pour la haute disponibilité.
- **Surveillance et outils** : `ceph status`, tableau de bord web, intégration **Prometheus** et **Grafana**.
