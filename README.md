# Bug Bounty Project Manager

Aplicació web **moderna i professional** per gestionar projectes de Bug Bounty amb checklist de seguretat, desenvolupada amb **arquitectura MVC**, **RESTful API**, i **tecnologies modernes**.

## 🚀 Característiques

- **Gestió de Projectes**: Crea i gestiona projectes de bug bounty
- **Gestió de Targets**: Assigna targets (objectius) a cada projecte
- **Checklist de Seguretat**: Més de 350 tests de seguretat predefinits organitzats en 30 categories
- **Notes per Item**: Cada item de checklist pot tenir les seves pròpies notes
- **Agregació Automàtica**: Les notes dels items s'agreguen automàticament al target
- **Dashboard Interactiu**: Visualitza l'estat dels teus projectes i targets
- **Tracking de Progrés**: Seguiment del percentatge de completació per cada target
- **Interfície Moderna**: UI responsive amb Bootstrap 5

## 📦 Components

- **Apache + PHP 8.2**: Servidor web amb PHP
- **MySQL 8.0**: Base de dades amb triggers automàtics
- **phpMyAdmin**: Interfície web per gestionar MySQL directament
- **Bootstrap 5**: Framework CSS per la interfície

## 🛠️ Instal·lació i Ús

### Iniciar els contenidors:
```bash
docker-compose up -d
```

### Aturar els contenidors:
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
  - Usuari: `bbpm_user`
  - Contrasenya: `bbpm_password`
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

### Categories & Checklist
- `GET /api/categories` - Llistar categories
- `GET /api/checklist` - Llistar items
- CRUD complet per categories i checklist items

**Documentació completa:** Veure [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

## 🔐 Credencials de MySQL

- **Root Password**: `root_password`
- **Database**: `bbpm_db`
- **User**: `bbpm_user`
- **Password**: `bbpm_password`

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
