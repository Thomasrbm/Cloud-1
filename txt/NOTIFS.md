# Notify et handlers

Tout se passe **pendant `ansible-playbook`**, et seulement là. Il n'y a aucun
mécanisme qui tourne en fond sur le serveur : si tu modifies un fichier à la
main sur le serveur, rien ne se déclenche avant le prochain lancement du playbook.

## 1. Les statuts d'une tâche

À chaque tâche, Ansible affiche un statut :

| Statut | Couleur | Signification | Notify ? |
|---|---|---|---|
| `ok` | vert | déjà dans le bon état, rien touché | ❌ |
| `changed` | jaune | a modifié quelque chose sur le serveur | ✅ |
| `skipping` | cyan | ignorée (un `when:` est faux) | ❌ |
| `failed` | rouge | erreur, le play s'arrête pour ce serveur | ❌ |
| `unreachable` | rouge | connexion SSH impossible | ❌ |

**Seul `changed` déclenche un `notify`.**

Le récap final les compte :

```
PLAY RECAP
1.2.3.4 : ok=42  changed=3  unreachable=0  failed=0  skipped=2
```

Si tu relances le playbook sans rien modifier, tu dois obtenir `changed=0` :
c'est la preuve d'idempotence.

## 2. Quand une tâche est `changed`

Pour `template` / `copy`, Ansible génère le fichier et le compare à celui du serveur :

- identique (contenu + permissions) → `ok`
- absent ou différent → il le remplace → `changed`

## 3. Le trajet d'une notification

```
Tâche ".env"       → changed → notify "Recreate stack" → mis en file d'attente
Tâche "compose"    → changed → notify "Recreate stack" → déjà en file, ignoré
Tâche "nginx.conf" → ok      → rien
... les autres rôles continuent ...
FIN DU PLAY        → "Recreate stack" s'exécute UNE seule fois
```

- Le `notify:` est lié au handler par son **nom exact** (sinon `handler not found`).
- Le handler **n'est pas exécuté tout de suite** : il est mis en attente.
- Il n'y a **pas de doublon** : 10 notifications donnent 1 exécution.
- À la **fin du play**, les handlers s'exécutent dans l'ordre où ils sont définis.

## 4. Dans ce projet

| Tâche qui notifie | Handler | Effet |
|---|---|---|
| `.env` et `docker-compose.yml` (`roles/stack`) | `Recreate stack` | `docker compose up -d --force-recreate` : recrée tous les conteneurs |
| `nginx.conf` (`roles/proxy`) | `Restart nginx` | `docker compose restart nginx` |
| config SSH (`roles/ssh_access`) | `Restart sshd` | recharge SSH sans couper la session |

Exemples :

| Ce que tu fais | Résultat |
|---|---|
| premier déploiement | fichiers créés → `changed` → handlers lancés |
| relance sans rien changer | tout `ok` → aucun handler |
| mot de passe changé dans le vault | `.env` `changed` → `Recreate stack` |
| `nginx.conf.j2` modifié | `changed` → `Restart nginx` |

## 5. Piège : un échec avant la fin

Si une tâche est `failed`, le play s'arrête et **les handlers en attente ne
tournent jamais**. À la relance, le fichier est déjà à jour (`ok`), donc plus de
notify : les conteneurs gardent l'ancienne config.

Solution : lancer avec `--force-handlers`, qui exécute les handlers en attente
même si une tâche échoue :

```
ansible-playbook playbook.yml --ask-vault-pass --force-handlers
```

(`meta: flush_handlers` dans une tâche force aussi l'exécution immédiate des
handlers en attente ; ce projet ne s'en sert pas.)
