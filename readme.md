# 🐳 WP-Dockit – Local WordPress Environment with Docker

**WP-Dockit** is a full-featured CLI-powered solution to spin up and manage multiple isolated WordPress environments locally using Docker.
Designed for developers and tinkerers, it offers **smart port handling**, **project-level control**, and **easy lifecycle management** of local WordPress sites.

---

## 📦 Features

- 🔧 Automatic setup with `Makefile` and Bash scripts
- 🌐 Shared Docker network for isolated WordPress environments
- 🔁 Port conflict prevention with smart detection
- 🚫 System port protection via `template.reserved_ports.env`
- 📂 Self-contained WordPress instances per folder (`docker-compose.yml` + `.env`)
- ⚙️ Custom `.env` generation per site with interactive prompts
- 🚦 Smart startup script with port checking and auto-correction
- 🔄 Auto-regeneration of reserved ports from active containers
- 🧹 Global cleanup for all WordPress containers and base services
- ❌ Per-project removal tool (`remove-site.sh`)
- 🧪 Port validation before container launch
- 📊 Optional phpMyAdmin for DB access and MailHog for mail testing
- ✅ Run multiple WordPress instances in parallel with safe isolation

---

## 🖥️ System Requirements

| OS         | Requirements                                                                 |
|------------|-------------------------------------------------------------------------------|
| **Linux**  | Docker, Bash                                                                 |
| **macOS**  | Docker Desktop, Bash (pre-installed)                                         |
| **Windows**| Docker Desktop + WSL2 + Git Bash (from Git for Windows or via VSCode)        |

> ⚠️ You **must be able to run Bash scripts**. On Windows, use **Git Bash** or the **WSL terminal**.

---

## 📁 Project Structure

```bash
scripts/
├── init.sh                     # Creates Docker network and starts core services (DB, MailHog, phpMyAdmin)
├── create-site.sh              # Interactive script to scaffold a new WordPress project
├── start-site.sh               # Safe startup script with port verification and service checks
├── stop-wp-site.sh             # Stops a running WordPress project from its folder
├── cleanup.sh                  # Stops and cleans up all WordPress containers and shared services
├── remove-site.sh              # Fully deletes a WordPress project and unregisters its port
├── regenerate_reserved_ports.sh# Rebuilds reserved_ports.env from active containers
├── reserved_ports.env          # Auto-managed list of reserved ports
├── template.reserved_ports.env # Static list of system/service ports to never assign
Makefile                        # Wrapper for all common commands
docker-compose.base.yml         # Shared services (MySQL, phpMyAdmin, MailHog)
```

---

## 🚀 Getting Started

### 1. Initialize Shared Network & Base Services

Create the shared Docker network and boot up MySQL, MailHog, and phpMyAdmin:

```bash
make init
```

### 2. Create a New WordPress Site

Launch an interactive setup to create a new WordPress project folder:

```bash
make new-site
```

🛠 Includes:
- Prompts for site folder name, site name, DB name/user/password
- Suggests or auto-assigns a free port ≥ 8000
- Checks for:
  - Port conflicts (running containers)
  - Reserved ports in `reserved_ports.env`
  - Critical ports from `template.reserved_ports.env`
- Generates:
  - `.env` file with full project configuration
  - `docker-compose.yml` based on templates
- Adds chosen port to `reserved_ports.env`

### 3. Start a WordPress Site Safely

Use the safe-start script to validate and launch a WordPress project:

```bash
make start-site
```

🧠 What it does:
- Ensures the port from `.env` is not in use or reserved
- If needed, proposes a new port and updates `.env`
- Starts core services if not already up
- Starts the WordPress container via Docker Compose

✅ You can run this command for run multiple sites in parallel (each site is separate by a comma e.g. site-1,site-2).

### 4. Stop a Specific WordPress Site

Navigate to the project directory and run:

```bash
make stop-site
```

This stops only the targeted WordPress instance without touching others or core services.


✅ You can run this command for stop multiple sites (each site is separate by a comma e.g. site-1,site-2 or all to stop all wordpress container currently running).

### 5. Remove a WordPress Project

Deletes an entire WordPress project safely:

```bash
make remove-site
```

🧨 Includes:
- Prompts for confirmation
- Stops and removes containers
- Deletes folder contents
- Removes port from `reserved_ports.env`

### 6. Cleanup All WordPress Sites & Services

Stop **everything**, including core services and all site containers:

```bash
make cleanup
```

🧹 This:
- Stops all `wordpress-*` containers
- Stops MailHog, MySQL, phpMyAdmin
- Removes the shared Docker network

### 7. Regenerate the Reserved Port List

Rebuild the `reserved_ports.env` file based on currently running containers and the `template.reserved_ports` if its exist (otherwise it will create it and you should add the port that you want to lock there):

```bash
make regenerate-ports
```

---

## 🛠 Makefile Commands

```make
init:                # Initialize shared network & core services
	@bash scripts/init.sh

new-site:            # Create new WordPress project interactively
	@bash scripts/create-site.sh

start-site:          # Start a WordPress project safely (port check)
	@bash scripts/start-site.sh

stop-site:           # Stop current WordPress project (from its folder)
	@bash scripts/stop-wp-site.sh

remove-site:         # Delete a WordPress project completely
	@bash scripts/remove-site.sh

cleanup:             # Stop and remove ALL WordPress containers + shared services
	@bash scripts/cleanup.sh

regenerate-ports:    # Rebuild reserved_ports.env dynamically
	@bash scripts/regenerate_reserved_ports.sh
```

---

## 💡 Tip: Reserve Specific Ports

To avoid assigning specific ports when you create a new site you can edit:

```bash
scripts/template.reserved_ports.env
```

> ⚠️ I recommend to not update immediately the reserved_ports.env instead you should update the template.reserved_ports.env and run `make regenerate-ports` in order to keep things clear.

***The RESERVED_PORTS variable present in the file reserved_ports.env will change everytime you add a project so you should keep away the port that your service are using in template.reserved_ports.env***

> Note: MailHog uses port 8025 by default and is automatically excluded from assignments.

---

## 📚 Notes

- You can host **multiple isolated WordPress sites** in parallel — each in its own folder.
- No port conflicts: each instance runs on a unique localhost port.
- phpMyAdmin runs at `http://localhost:8080`, MailHog at `http://localhost:8025`.
- All config is per-project and easy to back up or version.

---

## 🔄 Futur Improvements

- Add a command to add the possibility to add an hostname to the host file to use that instead of the ip address
- Add in the remove-site command the declaration in the host file
- More to come

---

## 🧠 Name & Credits

This project is called **WP-Dockit** — your personal CLI toolbox to dockerize and manage WordPress locally with zero hassle.

Crafted with ❤️ by Gaétan Gérard.

---

## ⚠️ License Notice

This project is currently released under the **Creative Commons BY-NC-SA 4.0** license, which allows non-commercial use, modification, and redistribution of the code.

**However, I reserve the right to change the license in the future**, especially if the project evolves into a version requiring more resources, maintenance, or support.

In such a case, a future version may be released under a different license, possibly commercial, to better reflect the needs related to development and distribution.

Thank you for your understanding and support!
