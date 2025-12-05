# 🎯 Bug Bounty Project Manager

<div align="center">

![PHP](https://img.shields.io/badge/PHP-8.2-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Bootstrap](https://img.shields.io/badge/Bootstrap-5-7952B3?style=for-the-badge&logo=bootstrap&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A modern, professional web application for managing Bug Bounty projects with comprehensive security testing checklists**

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [API](#-api-reference)

</div>

---

## 📋 Overview

Bug Bounty Project Manager (BBPM) is a full-featured web application designed for security researchers and penetration testers to organize, track, and document their bug bounty hunting activities. Built with modern **MVC architecture**, **RESTful API**, and **Docker containerization**, it provides a robust platform for managing security assessments.

### 🎯 Key Highlights

- **350+ Security Tests** across 30+ categories
- **Multi-type Target Support** (URLs, IPs, Domains)
- **Automated Note Aggregation** with severity classification
- **Multi-format Export** (TXT, Markdown, JSON, CSV, HTML)
- **RESTful API** for programmatic access
- **Real-time Progress Tracking** and interactive dashboards

---

## ✨ Features

### 🔐 Security Testing Management

- **Comprehensive Checklist**: Over 350 predefined security tests organized in 30+ categories
- **Custom Categories**: Create and manage your own test categories
- **Flexible Target Types**:
  - 🌐 **URLs**: Full web applications (e.g., `https://api.example.com/v1`)
  - 🖥️ **IPs**: IPv4 and IPv6 addresses (e.g., `192.168.1.100`, `2001:0db8::1`)
  - 🌍 **Domains**: Domain names (e.g., `example.com`, `subdomain.example.co.uk`)

### 📝 Notes & Documentation

- **Item-level Notes**: Add detailed notes to each checklist item
- **Severity Classification**: Tag findings as Critical, High, Medium, Low, or Info
- **Automatic Aggregation**: Notes automatically aggregate to target level with timestamps
- **Change History**: Full tracking of all note modifications
- **Advanced Views**:
  - Aggregated notes with Markdown formatting
  - Grouping by severity level
  - Grouping by category
  - Historical change tracking

### 📊 Project Management

- **Project Organization**: Create and manage multiple bug bounty projects
- **Target Assignment**: Assign multiple targets to each project
- **Progress Tracking**: Real-time completion percentage for each target
- **Interactive Dashboard**: Visualize project status and statistics
- **Filtering & Search**: Quickly find projects and targets

### 💾 Data Export & Backup

- **Multi-format Export**: Export findings in:
  - 📄 Plain Text (TXT)
  - 📝 Markdown (MD)
  - 📊 JSON
  - 📈 CSV
  - 🌐 HTML

### 🔌 RESTful API

Complete REST API for programmatic access to all resources:
- Projects: `GET /api/projects`, `POST /api/projects`, etc.
- Targets: `GET /api/targets`, `PUT /api/targets/{id}`, etc.
- Checklist Items: `GET /api/checklist/items`, etc.
- Categories: `GET /api/categories`, etc.
- Notes: `GET /api/notes`, `POST /api/notes`, etc.

### 🎨 Modern UI

- **Responsive Design**: Works on desktop, tablet, and mobile
- **Bootstrap 5**: Modern, clean interface
- **ES6+ JavaScript**: Fast, reactive frontend
- **Real-time Updates**: Dynamic content loading without page refreshes

---

## 🚀 Quick Start

### Prerequisites

- [Docker](https://www.docker.com/get-started) (20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (2.0+)
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/0xRh4ps00dy/bug-bounty-project-manager.git
cd bug-bounty-project-manager
```

2. **Start the containers**
```bash
docker-compose up -d
```

3. **Access the application**
- **Main Application**: http://localhost
- **phpMyAdmin**: http://localhost:8080
  - Username: `bbpm_user`
  - Password: `bbpm_password`

4. **Stop the containers**
```bash
docker-compose down
```

### First Steps

1. Navigate to http://localhost
2. Create your first project from the Dashboard
3. Add targets to your project (URLs, IPs, or Domains)
4. Start checking off security tests from the comprehensive checklist
5. Add notes with severity levels as you discover findings
6. Export your findings in your preferred format

---

## 📦 Architecture

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Web Server** | Apache 2.4 | HTTP server |
| **Backend** | PHP 8.2 | Application logic |
| **Database** | MySQL 8.0 | Data persistence |
| **Frontend** | Bootstrap 5 | Responsive UI |
| **API** | REST | Programmatic access |
| **Admin Panel** | phpMyAdmin | Database management |
| **Containers** | Docker Compose | Orchestration |

### Project Structure

```
bug-bounty-project-manager/
├── apache/                 # Apache + PHP Dockerfile
├── app/
│   ├── Controllers/        # MVC Controllers
│   ├── Models/            # Data models
│   ├── Views/             # View templates
│   └── Core/              # Core framework classes
├── backup/                # Backup scripts & storage
│   ├── backup-database.ps1    # Windows backup script
│   ├── backup-database.sh     # Linux/Mac backup script
│   ├── restore-database.ps1   # Windows restore script
│   ├── restore-database.sh    # Linux/Mac restore script
│   └── backups/              # Backup files (git-ignored)
├── config/                # Configuration files
├── mysql/                 # MySQL initialization
│   └── init.sql          # Database schema & seed data
├── public/               # Public web assets
│   ├── css/             # Stylesheets
│   └── js/              # JavaScript modules
├── routes/              # Route definitions
│   ├── web.php         # Web routes
│   └── api.php         # API routes
└── docker-compose.yml   # Docker services definition
```

### MVC Architecture

```
┌─────────────┐      ┌──────────────┐      ┌────────────┐
│   Routes    │─────▶│ Controllers  │─────▶│   Models   │
│  (web.php)  │      │ (Business    │      │  (Data     │
│  (api.php)  │      │   Logic)     │      │  Access)   │
└─────────────┘      └──────────────┘      └────────────┘
                            │                      │
                            ▼                      ▼
                     ┌──────────────┐      ┌────────────┐
                     │    Views     │      │   MySQL    │
                     │ (Templates)  │      │  Database  │
                     └──────────────┘      └────────────┘
```

---

## 🔧 Configuration

### Database Connection

Database credentials are configured in `docker-compose.yml`:

```yaml
environment:
  DB_HOST: db
  DB_PORT: 3306
  DB_NAME: bbpm_db
  DB_USER: bbpm_user
  DB_PASS: bbpm_password
```

### Port Configuration

Default ports can be modified in `docker-compose.yml`:

```yaml
ports:
  - "80:80"      # Web application
  - "3306:3306"  # MySQL
  - "8080:80"    # phpMyAdmin
```

### Health Checks

MySQL includes a health check to ensure the database is ready before the web container starts:

```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-proot_password"]
  interval: 5s
  timeout: 3s
  retries: 10
  start_period: 30s
```

---

## 📚 Documentation

### API Reference

#### Projects

- `GET /api/projects` - List all projects
- `GET /api/projects/{id}` - Get project details
- `POST /api/projects` - Create new project
- `PUT /api/projects/{id}` - Update project
- `DELETE /api/projects/{id}` - Delete project

#### Targets

- `GET /api/targets` - List all targets
- `GET /api/targets?project_id={id}` - Get targets by project
- `POST /api/targets` - Create new target
- `PUT /api/targets/{id}` - Update target
- `DELETE /api/targets/{id}` - Delete target

#### Checklist Items

- `GET /api/checklist/items` - List all checklist items
- `GET /api/checklist/items?target_id={id}` - Get items for target
- `POST /api/checklist/items/{id}/status` - Update item status

#### Notes

- `GET /api/notes?target_id={id}` - Get notes for target
- `POST /api/notes` - Create new note
- `PUT /api/notes/{id}` - Update note
- `DELETE /api/notes/{id}` - Delete note

### API Example

```bash
# Get all projects
curl http://localhost/api/projects

# Create a new project
curl -X POST http://localhost/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"HackerOne Project","description":"Testing example.com"}'

# Add a target
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"name":"Main Site","type":"url","value":"https://example.com"}'
```

---

## 🛠️ Development

### Adding Custom Categories

Navigate to the Categories management page to create custom test categories for your specific needs.

### Extending the Checklist

You can add custom checklist items through phpMyAdmin or via the API:

```sql
INSERT INTO checklist_items (category_id, description, is_default)
VALUES (1, 'Custom security test description', 1);
```

### Database Triggers

The application uses MySQL triggers for automatic note aggregation:

- `after_item_note_insert`: Aggregates new notes to target
- `after_item_note_update`: Updates aggregated notes on modification
- `after_item_note_delete`: Removes notes from aggregation on deletion

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with ❤️ for the Bug Bounty community
- Inspired by real-world penetration testing workflows
- Special thanks to all security researchers who provided feedback

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/0xRh4ps00dy/bug-bounty-project-manager/issues)
- **Documentation**: [Wiki](https://github.com/0xRh4ps00dy/bug-bounty-project-manager/wiki)

---

<div align="center">

**[⬆ Back to Top](#-bug-bounty-project-manager)**

Made with 🔒 by security researchers, for security researchers

</div>
```bash
docker-compose down
```

### Reiniciar després de canvis:
```bash
docker-compose restart
```

### Veure els logs:
```bash
docker-compose logs -f
```

### Recrear la base de dades:
```bash
docker-compose down
docker volume rm bug-bounty-project-manager_mysql_data
docker-compose up -d
```

## 🌐 Accedir als serveis

- **Aplicació Web**: http://localhost
- **phpMyAdmin**: http://localhost:8080
  - Usuari: `Bug Bounty Project Manager_user`
  - Contrasenya: `Bug Bounty Project Manager_password`
  - O com a root: `root` / `root_password`

## 📁 Estructura del projecte

```
.
├── docker-compose.yml          # Configuració dels serveis Docker
├── README.md                   # Aquesta documentació
├── apache/
│   └── Dockerfile             # Imatge personalitzada d'Apache + PHP
├── mysql/
│   └── init.sql              # Script d'inicialització de la BD amb dades de prova
└── www/                       # Aplicació web PHP
    ├── config.php            # Configuració de la base de dades
    ├── header.php            # Capçalera compartida
    ├── footer.php            # Peu de pàgina compartit
    ├── index.php             # Dashboard principal
    ├── projects.php          # CRUD de projectes
    ├── project_detail.php    # Detall d'un projecte
    ├── targets.php           # CRUD de targets
    ├── target_detail.php     # Detall d'un target amb checklist
    ├── categories.php        # CRUD de categories
    └── checklist.php         # CRUD de checklist items
```

## 🌐 Endpoints API

### Projects
- `GET /api/projects` - Llistar tots els projectes
- `GET /api/projects/{id}` - Obtenir un projecte
- `POST /api/projects` - Crear projecte
- `PUT /api/projects/{id}` - Actualitzar projecte
- `DELETE /api/projects/{id}` - Eliminar projecte

### Targets
- `GET /api/targets` - Llistar tots els targets
- `GET /api/targets/{id}` - Obtenir un target amb checklist
- `POST /api/targets` - Crear target (auto-assigna 367 items)
- `PUT /api/targets/{id}` - Actualitzar target
- `DELETE /api/targets/{id}` - Eliminar target

### Target Checklist
- `POST /api/targets/{targetId}/checklist/{itemId}/toggle` - Toggle item check
- `POST /api/targets/{targetId}/checklist/{itemId}/notes` - Actualitzar notes

### Notes Management (Nou!)
- `GET /api/targets/{id}/notes` - Obtenir notas agregadas del target
- `GET /api/targets/{id}/notes/history` - Historial de canvis de notes
- `GET /api/targets/{id}/notes/by-category` - Notas agrupades per categoria
- `GET /api/targets/{id}/notes/by-severity` - Notas agrupades per severitat
- `GET /api/targets/{id}/notes/export?format={txt|md|json|csv|html}` - Exportar notes en diversos formats

### Categories & Checklist
- `GET /api/categories` - Llistar categories
- `GET /api/checklist` - Llistar items
- CRUD complet per categories i checklist items

**Documentació completa:** Veure [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

## 🔐 Credencials de MySQL

- **Root Password**: `root_password`
- **Database**: `Bug Bounty Project Manager_db`
- **User**: `Bug Bounty Project Manager_user`
- **Password**: `Bug Bounty Project Manager_password`

## 💾 Base de Dades

L'script `init.sql` crea automàticament:

### Taules Principals
- `projects`: Projectes de bug bounty
- `targets`: Objectius dins de cada projecte
- `categories`: Categories de testing
- `checklist_items`: Plantilla de checklist items
- `target_checklist`: Checklist assignada a cada target

### Triggers Automàtics
- **update_target_notes_on_insert**: Actualitza notes del target quan s'afegeix un item
- **update_target_notes_on_update**: Actualitza notes del target quan es modifica un item
- **update_target_notes_on_delete**: Actualitza notes del target quan s'elimina un item

### Dades de Prova
El sistema inclou dades de prova amb:
- 4 projectes (E-commerce, Banking, Social Media, API)
- 9 targets distribuïts entre projectes
- 367 checklist items en 30 categories
- 35+ exemples d'items completats amb notes realistes

## 📝 Notes Tècniques

- Els fitxers PHP s'han de col·locar a la carpeta `www/`
- Les dades de MySQL es guarden en un volum persistent (`mysql_data`)
- Per connectar-te a MySQL des de PHP, utilitza `db` com a host
- El sistema utilitza PDO per la connexió a la base de dades
- Bootstrap 5 i Bootstrap Icons per la interfície

## 💻 Requisits

- Docker
- Docker Compose
- Navegador web modern (Chrome, Firefox, Edge, Safari)

## 🐛 Resolució de Problemes

### Port 80 o 3306 ja en ús
Si els ports ja estan en ús, pots modificar-los al fitxer `docker-compose.yml`:
```yaml
web:
  ports:
    - "8000:80"  # Canvia 80 per un altre port
    
db:
  ports:
    - "3307:3306"  # Canvia 3306 per un altre port
```

### Errors de connexió a MySQL
Espera uns segons després d'iniciar els contenidors perquè MySQL s'inicialitzi completament:
```bash
docker-compose logs -f db
```

### Reset complet de la base de dades
```bash
docker-compose down
docker volume rm bug-bounty-project-manager_mysql_data
docker-compose up -d
```

## 📄 Llicència

Aquest projecte és de codi obert per a ús educatiu i de testing de seguretat.
