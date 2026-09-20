# Clés publiques autorisées

Dépose ici **un fichier `.pub` par machine** devant pouvoir déployer / se
connecter au serveur :

```
roles/ssh_access/files/
├── fixe.pub
├── portable.pub
└── poste42.pub
```

Sur la nouvelle machine :

```sh
ssh-keygen -t ed25519 -C "portable"     # si tu n'as pas encore de clé
cat ~/.ssh/id_ed25519.pub               # copier la ligne complète
```

Colle la ligne dans un nouveau fichier ici, commit, puis relance le playbook
**depuis une machine déjà autorisée** :

```sh
ansible-playbook playbook.yml --ask-vault-pass
```

⚠️ Ne mets **jamais** ici une clé privée (`id_ed25519`, `*.pem`, sans extension
`.pub`) : `.gitignore` bloque `*.pem` et `*.key`, mais reste vigilant.
