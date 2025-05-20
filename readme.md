# 🐳 WP-Dockit – Local WordPress Environment with Docker

**WP-Dockit** is a CLI-powered solution to spin up and manage multiple WordPress environments locally using Docker.
It features **automatic port assignment**, a **shared Docker network**, and clean **multi-project management** through simple scripts and a `Makefile`.

---

## 📦 Features

- 🔧 Automatic setup with `Makefile` and Bash scripts
- 🌐 Shared Docker network for isolated WordPress environments
- 🔁 Port conflict prevention with smart detection and reserved port list
- 📂 Self-contained WordPress instances per folder (`docker-compose.yml` + `.env`)
- 🧹 Cleanup tools to stop and remove all WordPress containers

---

## 🖥️ System Requirements

| OS        | Requirements                                                                 |
|-----------|-------------------------------------------------------------------------------|
| **Linux** | Docker, Bash                                                                 |
| **macOS** | Docker Desktop, Bash (pre-installed)                                         |
| **Windows** | Docker Desktop + WSL2 + Git Bash (included with Git for Windows or via VSCode) |

> ⚠️ You **must be able to run Bash scripts**. On Windows, use **Git Bash** or the **WSL terminal**.

---

## 📁 Project Structure



```bash
scripts/
├── init.sh # Creates Docker network and starts core services (DB, MailHog, phpMyAdmin)
├── create-site.sh # Interactive script to scaffold a new WordPress project
├── cleanup.sh # Stops and cleans up all WordPress containers and shared services
├── reserved_ports.env # List of reserved ports (auto-managed)
Makefile # Wrapper for all commands
docker-compose.base.yml # Core services (MySQL, MailHog, phpMyAdmin)
```

---

## 🚀 Getting Started

### 1. Initialize Shared Network & Base Services

This command creates the `shared_net` Docker network (if missing) and starts base services like MySQL, phpMyAdmin, and MailHog:


```bash
   make init
```

### 2. Create a New WordPress Site
Launch an interactive setup to configure a new WordPress site:

```bash
   make new-site
```

🛠 What it does:
- Asks for:
   - Site directory name `SITE_DIR`
   - WordPress site name `SITE_NAME`
   - DB credentials `DB_NAME` / `DB_USER` / `DB_PASSWORD`
   - If no Port selected, automatically finds a free port (starting at `8000`)
- Avoids:
   - Ports already in use
   - Ports listed in `scripts/reserved_ports.env`
- Generates:
   - `.env` with variables
   - `docker-compose.yml` for the new WordPress instance
Updates `reserved_ports.env` so ports aren’t reused in the future

### 3. Start a WordPress Site

Go to the created folder and launch Docker:

```bash
   cd my-site
   docker compose up -d
```
Visit your new site at `http://localhost:<assigned-port>`

### 4. Cleanup All WordPress Sites & Services

Stops all WordPress containers and core services, then removes the shared network:

```bash
   make cleanup
```

What it does:

- Stops all containers starting with `wordpress-`
- Stops services from `docker-compose.base.yml` (db, phpMyAdmin, MailHog)
- Removes the Docker network `shared_net`

---

## 🛠 Available Makefile Commands
```bash
   init:
	   @bash scripts/init.sh

   new-site:
	   @bash scripts/create-site.sh

   cleanup:
	   @bash scripts/cleanup.sh
```

---

## 💡 Tip: Reserve Specific Ports
If you want to prevent specific ports from being auto-assigned to new WordPress instances:

Edit the file:
```bash
   scripts/reserved_ports.env
```

Example:

```bash
   RESERVED_PORTS="8000 8001 8025"
```
> Port 8025 is already reserved by default for MailHog and will be ignored by the system.

---

## 📚 Notes
- You can manage as many WordPress projects as you want — each one lives in its own folder.
- You can run several WordPress instances in parallel as long as ports don’t conflict.
- Ensure `docker compose` is available (`Docker Desktop` installs it by default).

## 🧠 Name & Credits
This project is called WP-Dockit — your personal tool to dockerize WordPress efficiently.
Maintained with ❤️ by Gaétan Gérard.