# Bug Bounty Project Manager

Aplicació web **moderna i professional** per gestionar projectes de Bug Bounty amb checklist de seguretat, desenvolupada amb **arquitectura MVC**, **RESTful API**, i **tecnologies modernes**.

## 🚀 Característiques

### Arquitectura Moderna
- **MVC Pattern**: Separació clara entre Models, Views i Controllers
- **RESTful API**: Endpoints JSON per integració amb eines externes
- **URL Routing**: Sistema de routes modern amb paràmetres dinàmics
- **PSR-4 Autoloading**: Gestió automàtica de classes amb Composer
- **Fetch API**: JavaScript modern amb AJAX sense recarregar pàgina
- **Single Page Interactions**: Experiència d'usuari fluida

### Funcionalitats del Sistema
- **Gestió de Projectes**: CRUD complet amb estadístiques
- **Gestió de Targets**: Assignació automàtica de checklist completa (367 items)
- **Checklist de Seguretat**: 30 categories amb més de 350 tests predefinits
- **Notes per Item**: Agregació automàtica amb MySQL triggers
- **Dashboard Interactiu**: Visualització d'estadístiques en temps real
- **API REST**: Tots els endpoints disponibles en format JSON

## 📦 Stack Tecnològic

- **Backend**: PHP 8.2 amb arquitectura MVC
- **Base de Dades**: MySQL 8.0 amb triggers automàtics
- **Servidor Web**: Apache 2.4 amb mod_rewrite
- **Frontend**: Bootstrap 5 + JavaScript ES6+ + Fetch API
- **Contenidors**: Docker + Docker Compose
- **Gestió de Dependències**: Composer
- **Administració BD**: phpMyAdmin

## 🛠️ Instal·lació

### Prerequisits
- Docker
- Docker Compose
- Git

### Pas a Pas

1. **Clonar el repositori**
```bash
git clone https://github.com/tuusuari/bug-bounty-project-manager.git
cd bug-bounty-project-manager
```

2. **Iniciar els contenidors**
```bash
docker-compose up -d --build
```

3. **Esperar a que s'instal·lin les dependències**
El contenidor web executarà automàticament `composer install` al iniciar.

4. **Accedir a l'aplicació**
- **Aplicació**: http://localhost
- **phpMyAdmin**: http://localhost:8080

## 📁 Estructura del Projecte

```
.
├── app/
│   ├── Controllers/          # Controladors RESTful
│   │   ├── DashboardController.php
│   │   ├── ProjectController.php
│   │   ├── TargetController.php
│   │   ├── CategoryController.php
│   │   └── ChecklistController.php
│   ├── Models/               # Models amb lògica de negoci
│   │   ├── Project.php
│   │   ├── Target.php
│   │   ├── Category.php
│   │   └── ChecklistItem.php
│   ├── Views/                # Vistes amb templates
│   │   ├── layouts/          # Layouts reutilitzables
│   │   ├── dashboard/
│   │   ├── projects/
│   │   ├── targets/
│   │   ├── categories/
│   │   └── checklist/
│   └── Core/                 # Classes del framework
│       ├── Router.php        # Sistema d'enrutament
│       ├── Controller.php    # Controlador base
│       ├── Model.php         # Model base
│       └── Database.php      # Gestió de connexions
├── config/
│   └── database.php          # Configuració de BD
├── public/                   # Document root
│   ├── index.php             # Front controller
│   ├── .htaccess             # URL rewriting
│   └── assets/
│       ├── css/
│       │   └── style.css     # Estils personalitzats
│       └── js/
│           └── app.js        # JavaScript modern amb Fetch API
├── routes/
│   ├── web.php               # Routes web
│   └── api.php               # Routes API
├── mysql/
│   └── init.sql              # Inicialització de BD
├── apache/
│   └── Dockerfile            # Imatge PHP + Apache + Composer
├── composer.json             # Dependències PHP
├── docker-compose.yml        # Configuració de serveis
└── README.md
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

### Categories
- `GET /api/categories` - Llistar categories
- `POST /api/categories` - Crear categoria
- `PUT /api/categories/{id}` - Actualitzar categoria
- `DELETE /api/categories/{id}` - Eliminar categoria

### Checklist Items
- `GET /api/checklist` - Llistar items
- `GET /api/checklist?category_id={id}` - Filtrar per categoria
- `POST /api/checklist` - Crear item
- `PUT /api/checklist/{id}` - Actualitzar item
- `DELETE /api/checklist/{id}` - Eliminar item

## 💻 Ús de l'API

### Exemple: Crear un projecte
```bash
curl -X POST http://localhost/api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Project",
    "description": "Test project",
    "status": "active"
  }'
```

### Exemple: Obtenir targets
```bash
curl http://localhost/api/targets
```

### Exemple: Toggle checklist item
```bash
curl -X POST http://localhost/api/targets/1/checklist/5/toggle \
  -H "Content-Type: application/json" \
  -d '{"is_checked": 1}'
```

## 🎨 Funcionalitats Frontend

- **AJAX Forms**: Formularis que no recarreguen la pàgina
- **Real-time Updates**: Actualització de progress bars en temps real
- **Toast Notifications**: Notificacions elegants amb Bootstrap
- **Loading States**: Indicadors visuals durant operacions
- **Responsive Design**: Optimitzat per mòbil i desktop
- **Modal Dialogs**: Edició in-place sense canviar de pàgina

## 🔐 Credencials

### MySQL
- **Host**: db (dins de Docker) / localhost:3306 (extern)
- **Database**: bbpm_db
- **User**: bbpm_user
- **Password**: bbpm_password
- **Root Password**: root_password

### phpMyAdmin
- URL: http://localhost:8080
- Usuari: `bbpm_user` / Password: `bbpm_password`
- O com a root: `root` / `root_password`

## 🗄️ Base de Dades

### Taules
- **projects**: Projectes de bug bounty
- **targets**: Objectius dins dels projectes
- **categories**: Categories de testing (Recon, XSS, SQLi, etc.)
- **checklist_items**: Plantilla de tests (367 items)
- **target_checklist**: Checklist assignada a cada target

### Triggers MySQL
- **update_target_notes_on_insert**: Agrega notes quan s'afegeix un item
- **update_target_notes_on_update**: Actualitza notes quan es modifica
- **update_target_notes_on_delete**: Elimina notes quan s'esborra

### Dades de Prova
El sistema s'inicia amb:
- 4 projectes exemple
- 9 targets distribuïts
- 30 categories de seguretat
- 367 checklist items
- Exemples d'ús amb notes realistes

## 🚀 Comandes Útils

### Iniciar l'aplicació
```bash
docker-compose up -d
```

### Aturar l'aplicació
```bash
docker-compose down
```

### Rebuild després de canvis al Dockerfile
```bash
docker-compose up -d --build
```

### Veure logs
```bash
docker-compose logs -f web
```

### Accedir al contenidor web
```bash
docker exec -it bbpm_web bash
```

### Executar Composer manualment
```bash
docker exec bbpm_web composer install
docker exec bbpm_web composer update
docker exec bbpm_web composer dump-autoload
```

### Reset complet de la BD
```bash
docker-compose down
docker volume rm bug-bounty-project-manager_mysql_data
docker-compose up -d
```

## 🐛 Resolució de Problemes

### Port 80 ja en ús
Modifica `docker-compose.yml`:
```yaml
web:
  ports:
    - "8000:80"  # Canvia 80 per 8000
```

### Errors de Composer
```bash
docker exec bbpm_web composer install
```

### Errors de permisos
```bash
docker exec bbpm_web chown -R www-data:www-data /var/www/html
```

### .htaccess no funciona
Verifica que mod_rewrite està habilitat:
```bash
docker exec bbpm_web apache2ctl -M | grep rewrite
```

## 🎯 Característiques Tècniques Destacades

### Arquitectura
- ✅ Patrón MVC amb separació de concerns
- ✅ Router amb paràmetres dinàmics i named routes
- ✅ Controllers amb suport dual: HTML i JSON
- ✅ Models amb query builder i relacions
- ✅ Vistes amb sistema de layouts
- ✅ PSR-4 Autoloading amb Composer

### API
- ✅ RESTful endpoints amb verbs HTTP correctes
- ✅ Resposta JSON automàtica per requests AJAX
- ✅ Gestió d'errors amb HTTP status codes
- ✅ Suport per Content-Type: application/json

### Frontend
- ✅ JavaScript modular amb classes ES6+
- ✅ Fetch API per requests AJAX
- ✅ Event delegation per rendiment
- ✅ Loading states i error handling
- ✅ Toast notifications amb Bootstrap
- ✅ Forms amb validació i feedback visual

### Seguretat
- ✅ PDO amb prepared statements
- ✅ Escapament de HTML amb htmlspecialchars()
- ✅ CSRF protection (a implementar)
- ✅ Validació d'input al servidor

## 📚 Properes Funcionalitats

- [ ] Autenticació i autorització d'usuaris
- [ ] CSRF protection amb tokens
- [ ] Paginació en llistats
- [ ] Cerca i filtres avançats
- [ ] Export a PDF
- [ ] WebSockets per actualitzacions en temps real
- [ ] CLI per gestió de projectes
- [ ] Tests automatitzats (PHPUnit)

## 📄 Llicència

Aquest projecte és de codi obert per a ús educatiu i de testing de seguretat.

## 👨‍💻 Autor

Desenvolupat amb ❤️ per a la comunitat de Bug Bounty Hunters

---

**Note**: Aquesta és una eina de gestió de projectes. Utilitza'la de manera responsable i sempre amb autorització per realitzar tests de seguretat.
