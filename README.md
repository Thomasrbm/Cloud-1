<div align="center">

# Cloud-1

**Deploy a complete WordPress stack on a bare cloud instance, in one command — 42 School project.**

*Ansible + Docker Compose on AWS EC2 (Ubuntu 22.04) — nine idempotent roles take a fresh VM to a TLS-terminated WordPress, MySQL and phpMyAdmin stack, with every secret encrypted by Ansible Vault.*

</div>

---

## Table of contents
1. [What it does](#what-it-does)
2. [Architecture](#architecture)
3. [The roles](#the-roles)
4. [One compose file per component](#one-compose-file-per-component)
5. [Secrets — Ansible Vault](#secrets--ansible-vault)
6. [Idempotency](#idempotency)
7. [Security](#security)
8. [Teardown](#teardown)
9. [Usage](#usage)
10. [Defense — verification commands](#defense--verification-commands)
11. [Notes](#notes)

---

## What it does

```sh
ansible-playbook playbook.yml --ask-vault-pass
```

From an untouched Ubuntu instance, that single command:

| Step | Result |
|---|---|
| Prepare the host | SSH keys authorized, 2 GB swap, Docker Engine + Compose plugin, firewall |
| Build the stack | project dir, `.env` rendered from the vault, bridge network, named volumes |
| Run the services | MySQL, WordPress (php-fpm), phpMyAdmin, nginx |
| Install the site | WordPress installed by `wp-cli` — the site is live, no setup wizard |
| Expose it | nginx is the **only** container publishing ports (80 → 301 → 443) |

`git clone` + the vault password is all it takes to deploy from any machine.

---

## Architecture

```
                         Internet
                            │
                  AWS Security Group  (22 / 80 / 443)
                            │
                  UFW on the instance (deny by default)
                            │
      ┌─────────────────────┼──────────── EC2 t3.micro · Ubuntu 22.04 ─┐
      │                     ▼                                          │
      │   ┌──────────────────────────────┐                             │
      │   │  nginx:alpine  :80  :443     │  self-signed TLS, 80 → 443  │
      │   └──────┬───────────────┬───────┘                             │
      │     *.php│ FastCGI :9000 │ /phpmyadmin/  proxy_pass :80        │
      │          ▼               ▼                                     │
      │   ┌─────────────┐  ┌─────────────┐                             │
      │   │ wordpress   │  │ phpmyadmin  │        bridge: wp_network   │
      │   │ php8.1-fpm  │  └──────┬──────┘                             │
      │   └──────┬──────┘         │                                    │
      │          └───────┬────────┘                                    │
      │                  ▼  :3306 (never published)                    │
      │           ┌─────────────┐                                      │
      │           │  mysql:8.0  │                                      │
      │           └─────────────┘                                      │
      │                                                                │
      │   volumes:  wp_data (shared by nginx + wordpress) · mysql_data │
      └────────────────────────────────────────────────────────────────┘
```

Only official images are used — no `build:`, nothing to rebuild, nothing to cache.

---

## The roles

`playbook.yml` runs them in order; every role has its own tag, so any part can be replayed alone.

| # | Role | Tags | What it does |
|---|---|---|---|
| 0 | `ssh_access` | `ssh` | Authorizes each machine's public key (`files/*.pub`) — no shared `.pem`; enables root login **by key only** |
| 1 | `swap` | `swap` `system` | 2 GB swap file, `swappiness=10` — a t3.micro has 1 GB RAM and no swap |
| 2 | `docker` | `docker` | Official Docker apt repo + GPG key, Engine and Compose plugin |
| 3 | `ufw` | `ufw` `security` | Deny incoming by default, allow 22 / 80 / 443 only |
| 4 | `stack` | `stack` | `/opt/wordpress`, `.env` (mode `0600`), network and named volumes |
| 5 | `db` | `db` | MySQL 8.0, no published port |
| 6 | `wordpress` | `wordpress` `wp` | php-fpm, waits for extraction, then `wp core install` |
| 7 | `phpmyadmin` | `phpmyadmin` `pma` | Database admin, served under `/phpmyadmin/` |
| 8 | `proxy` | `proxy` `nginx` | Self-signed certificate, nginx config, final convergence of the stack |

```sh
ansible-playbook playbook.yml --tags phpmyadmin --ask-vault-pass   # redeploy one component
```

---

## One compose file per component

Each role drops its own compose file; Docker merges them through `COMPOSE_FILE`, written into the `.env`:

```
COMPOSE_FILE=docker-compose.yml:compose.db.yml:compose.wordpress.yml:compose.phpmyadmin.yml:compose.proxy.yml
```

| File | Owner role | Content |
|---|---|---|
| `docker-compose.yml` | `stack` | `wp_network` (bridge), `mysql_data`, `wp_data` |
| `compose.db.yml` | `db` | `mysql` |
| `compose.wordpress.yml` | `wordpress` | `wordpress` + `wpcli` (profile `tools`, only run on demand) |
| `compose.phpmyadmin.yml` | `phpmyadmin` | `phpmyadmin` |
| `compose.proxy.yml` | `proxy` | `nginx` |

Result: a plain `docker compose ps` in `/opt/wordpress` sees the whole stack, while each component stays deployable on its own.

---

## Secrets — Ansible Vault

```
group_vars/webservers.yml   (AES-256, committed)
        │   ansible-playbook --ask-vault-pass  →  decrypted in RAM only
        ▼
roles/stack/templates/env.j2      {{ mysql_password }}   ← Ansible, at deploy time
        ▼
/opt/wordpress/.env  (0600, root)  ${MYSQL_PASSWORD}     ← Docker, at container start
        ▼
containers
```

- The encrypted file **is** versioned — that is the point of the vault: the repo is self-sufficient.
- Templates (`.j2`) and compose files only ever contain variables, never values.
- The vault password is written nowhere in the project (`.gitignore` also blocks `*.pem`, `*.key`, `vault_pass.txt`…).
- `group_vars/webservers.yml.example` shows the expected keys.

```sh
ansible-vault view  group_vars/webservers.yml
ansible-vault edit  group_vars/webservers.yml
ansible-vault rekey group_vars/webservers.yml
```

---

## Idempotency

Running the playbook twice changes nothing the second time — `PLAY RECAP … changed=0`.

| Mechanism | Where |
|---|---|
| `creates:` | TLS certificate is generated only if absent |
| `changed_when:` on Docker output | a container is `changed` only if it was `Created`, `Started` or `Recreated` |
| `wp core is-installed` | WordPress is installed only once |
| `until:` / `retries:` | waits for WordPress files to be extracted instead of racing them |
| handlers + `notify` | nginx and sshd restart only when their config actually changed |
| `validate: sshd -t` | a broken `sshd_config` is refused before it can lock us out |

---

## Security

- **Two firewalls**: the AWS Security Group outside, UFW inside — both must allow a port.
- **MySQL is never exposed**: reachable only on `wp_network`.
- **HTTP → HTTPS**: port 80 only answers with a `301`.
- **SSH**: keys only, root login `prohibit-password`; the cloud-image forced command blocking root is stripped, and drop-ins forcing `PermitRootLogin no` are neutralized.
- **Docker data**: `/var/lib/docker` is `drwx--x---`, root only; `.env` is `0600`.
- **One key per machine**: laptop, desktop and school workstation each add their own public key — revoking one never means rotating all.

---

## Teardown

`teardown.yml` resets the server so the full deployment can be replayed in front of an evaluator.

| Level | Command | Removes |
|---|---|---|
| Standard | `ansible-playbook teardown.yml --ask-vault-pass` | containers, images, volumes, `/opt/wordpress` — Docker stays |
| Full | `… -e full_wipe=true` | + Docker packages, apt repo, GPG key, swap, UFW rules — back to a bare Ubuntu |

Guard rails: an interactive `oui` confirmation, and an `assert` refusing to `rm -rf` a suspicious `project_dir` (`/`, `/etc`, `/usr`…).

---

## Usage

```sh
# 1. Dependencies
ansible-galaxy collection install -r requirements.yml     # community.general, ansible.posix

# 2. Target — inventory.ini
[webservers]
server1 ansible_host=<PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/cloud1-aws.pem

# 3. Deploy
ansible -m ping webservers
ansible-playbook playbook.yml --ask-vault-pass
```

| Page | URL |
|---|---|
| WordPress | `https://<PUBLIC_IP>/` |
| WordPress admin | `https://<PUBLIC_IP>/wp-admin` |
| phpMyAdmin | `https://<PUBLIC_IP>/phpmyadmin/` |

The certificate is self-signed — the browser warning is expected.

---

## Defense — verification commands

```sh
# Only 22 / 80 / 443 open from outside, 3306 absent
nmap -Pn <PUBLIC_IP>

# No secret in clear text
grep -rn "password" --include='*.yml' --include='*.j2' --include='*.cfg' . | grep -v vault
head -1 group_vars/webservers.yml                       # $ANSIBLE_VAULT;1.1;AES256

# One container per service, all on the same bridge
ansible server1 -b --ask-vault-pass -a "chdir=/opt/wordpress docker compose ps"
ansible server1 -b --ask-vault-pass -a "docker network inspect wordpress_wp_network"

# Persistent data in named volumes, root-only
ansible server1 -b --ask-vault-pass -a "docker volume ls"
ansible server1 -b --ask-vault-pass -a "ls -ld /var/lib/docker/volumes"

# Restart one service without touching the others
ansible server1 -b --ask-vault-pass -a "chdir=/opt/wordpress docker compose restart mysql"

# Official images only, nothing built
find . -name "Dockerfile*"
```

---

## Notes

- **Why swap on a t3.micro** — 1 GB of RAM: an `apt install` next to MySQL is enough to get containers OOM-killed.
- **Why the `ubuntu` user** — AWS forbids direct root login on its AMIs; `become: true` uses the AMI's passwordless sudo.
- **Speed** — `pipelining = True` and `ControlPersist=300s` in `ansible.cfg`: one SSH round-trip per task instead of four.
- **Stuck on `Gathering Facts`** while a manual `ssh` works — a frozen multiplexed socket: `rm -rf ~/.ansible/cp`.
- **Cost** — ~10 $/month for the t3.micro + 20 GB gp3 in `eu-north-1`; stop the instance when idle, release the Elastic IP at the end.

Detailed notes (in French) live in [`txt/`](txt/): AWS setup, vault, containers, handlers, defense walkthrough.

---

<div align="center">

*Built by **thomasrbm** — 42 School*

</div>
