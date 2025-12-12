# 🎯 Bug Bounty Project Manager

<div align="center">

![PHP](https://img.shields.io/badge/PHP-8.2-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Bootstrap](https://img.shields.io/badge/Bootstrap-5-7952B3?style=for-the-badge&logo=bootstrap&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Aplicación web moderna y profesional para gestionar proyectos de Bug Bounty con checklists de pruebas de seguridad completas**

[Características](#-características) • [Inicio Rápido](#-inicio-rápido) • [Documentación](#-documentación) • [API](#-referencia-de-api)

</div>

---

## 📋 Descripción General

Bug Bounty Project Manager (BBPM) es una aplicación web completa diseñada para investigadores de seguridad y pentesters para organizar, seguir y documentar su actividad de bug bounty. Construida con arquitectura **MVC**, **API REST** y **contenedores Docker**, ofrece una plataforma robusta para gestionar evaluaciones de seguridad.

### 🎯 Puntos Destacados

- **350+ pruebas de seguridad** en más de 30 categorías
- **Soporte de múltiples tipos de objetivo** (URLs, IPs, dominios)
- **Agregación automática de notas** con clasificación por severidad
- **Exportación en múltiples formatos** (TXT, Markdown, JSON, CSV, HTML)
- **API REST** para acceso programático
- **Seguimiento de progreso en tiempo real** y paneles interactivos

---

## ✨ Características

### 🔐 Gestión de Pruebas de Seguridad

- **Checklist completa**: Más de 350 pruebas predefinidas en 30+ categorías
- **Categorías personalizadas**: Crea y gestiona tus propias categorías de prueba
- **Tipos de objetivo flexibles**:
  - 🌐 **URLs**: Aplicaciones web completas (ej. `https://api.example.com/v1`)
  - 🖥️ **IPs**: Direcciones IPv4 e IPv6 (ej. `192.168.1.100`, `2001:0db8::1`)
  - 🌍 **Dominios**: Nombres de dominio (ej. `example.com`, `subdomain.example.co.uk`)

### 📝 Notas y Documentación

- **Notas por ítem**: Añade notas detalladas a cada elemento del checklist
- **Clasificación por severidad**: Etiqueta hallazgos como Crítico, Alto, Medio, Bajo o Info
- **Agregación automática**: Las notas se agregan al nivel del objetivo con marcas de tiempo
- **Historial de cambios**: Seguimiento completo de modificaciones de notas
- **Vistas avanzadas**:
  - Notas agregadas con formato Markdown
  - Agrupación por severidad
  - Agrupación por categoría
  - Historial de cambios

### 📊 Gestión de Proyectos

- **Organización de proyectos**: Crea y administra múltiples proyectos de bug bounty
- **Asignación de objetivos**: Asigna varios objetivos a cada proyecto
- **Seguimiento de progreso**: Porcentaje de completado en tiempo real por objetivo
- **Dashboard interactivo**: Visualiza estado y estadísticas de proyectos
- **Filtrado y búsqueda**: Encuentra rápido proyectos y objetivos

### 💾 Exportación y Copias de Seguridad

- **Exportación multi‑formato**:
  - 📄 Texto plano (TXT)
  - 📝 Markdown (MD)
  - 📊 JSON
  - 📈 CSV
  - 🌐 HTML

### 🔌 API REST

API completa para acceso programático a todos los recursos:
- Proyectos: `GET /api/projects`, `POST /api/projects`, etc.
- Objetivos: `GET /api/targets`, `PUT /api/targets/{id}`, etc.
- Ítems de Checklist: `GET /api/checklist/items`, etc.
- Categorías: `GET /api/categories`, etc.
- Notas: `GET /api/notes`, `POST /api/notes`, etc.

### 🎨 UI Moderna

- **Diseño responsivo**: Funciona en escritorio, tablet y móvil
- **Bootstrap 5**: Interfaz moderna y limpia
- **JavaScript ES6+**: Frontend rápido y reactivo
- **Actualizaciones en tiempo real**: Contenido dinámico sin recargar página

---

## 🚀 Inicio Rápido

### Requisitos Previos

- [Docker](https://www.docker.com/get-started) (20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (2.0+)
- Git

### Instalación

1. **Clona el repositorio**
```bash
git clone https://github.com/0xRh4ps00dy/bug-bounty-project-manager.git
cd bug-bounty-project-manager
```

2. **Levanta los contenedores**
```bash
docker-compose up -d
```

3. **Accede a la aplicación**
- **Aplicación principal**: http://localhost
- **phpMyAdmin**: http://localhost:8080
  - Usuario: `bbpm_user`
  - Contraseña: `bbpm_password`

4. **Detén los contenedores**
```bash
docker-compose down
```

### Primeros Pasos

1. Entra a http://localhost
2. Crea tu primer proyecto desde el Dashboard
3. Añade objetivos al proyecto (URLs, IPs o Dominios)
4. Empieza a marcar las pruebas de la checklist
5. Añade notas con niveles de severidad al encontrar hallazgos
6. Exporta tus hallazgos en el formato que prefieras

---

## 📦 Arquitectura

### Stack Tecnológico

| Componente     | Tecnología  | Propósito                 |
|----------------|-------------|---------------------------|
| **Servidor Web** | Apache 2.4 | Servidor HTTP             |
| **Backend**      | PHP 8.2    | Lógica de aplicación      |
| **Base de Datos**| MySQL 8.0  | Persistencia de datos     |
| **Frontend**     | Bootstrap 5| UI responsiva             |
| **API**          | REST       | Acceso programático       |
| **Panel DB**     | phpMyAdmin | Administración de la BD   |
| **Contenedores** | Docker Compose | Orquestación          |

### Estructura del Proyecto

```
bug-bounty-project-manager/
├── apache/                 # Dockerfile de Apache + PHP
├── app/
│   ├── Controllers/        # Controladores MVC
│   ├── Models/             # Modelos de datos
│   ├── Views/              # Vistas / plantillas
│   └── Core/               # Clases núcleo del framework
├── backup/                 # Scripts y almacenamiento de backups
│   ├── backup.sh           # Backup manual (Linux/Mac)
│   ├── restore.sh          # Restauración (Linux/Mac)
│   ├── auto-backup.sh      # Backup para cron
│   └── backups/            # Copias de seguridad (git-ignored)
├── config/                 # Archivos de configuración
├── mysql/                  # Inicialización de MySQL
│   └── migrations/         # Migraciones SQL
├── public/                 # Activos públicos (CSS, JS, imágenes)
├── routes/                 # Definición de rutas web y API
└── docker-compose.yml      # Definición de servicios Docker
```

### Arquitectura MVC

```
┌─────────────┐      ┌──────────────┐      ┌────────────┐
│   Rutas     │─────▶│ Controladores│─────▶│   Modelos   │
│ (web/api)   │      │ (Lógica)     │      │ (Datos)    │
└─────────────┘      └──────────────┘      └────────────┘
                            │                      │
                            ▼                      ▼
                     ┌──────────────┐      ┌────────────┐
                     │    Vistas    │      │   MySQL    │
                     │ (Plantillas) │      │  Base de   │
                     └──────────────┘      │  Datos     │
                                           └────────────┘
```

---

## 🔧 Configuración

### Conexión a la Base de Datos

Las credenciales se configuran en `docker-compose.yml` o en `.env`:

```yaml
environment:
  DB_HOST: db
  DB_PORT: 3306
  DB_NAME: bbpm_db
  DB_USER: bbpm_user
  DB_PASS: bbpm_password
```

### Puertos

```yaml
ports:
  - "80:80"      # Aplicación web
  - "3306:3306"  # MySQL
  - "8080:80"    # phpMyAdmin
```

### Health Checks

MySQL incluye un health check para garantizar que la base esté lista:

```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-proot_password"]
  interval: 5s
  timeout: 3s
  retries: 10
  start_period: 30s
```

---

## 📚 Documentación

### Referencia de API

#### Proyectos
- `GET /api/projects` - Lista todos los proyectos
- `GET /api/projects/{id}` - Detalles de un proyecto
- `POST /api/projects` - Crea un proyecto
- `PUT /api/projects/{id}` - Actualiza un proyecto
- `DELETE /api/projects/{id}` - Elimina un proyecto

#### Objetivos
- `GET /api/targets` - Lista todos los objetivos
- `GET /api/targets?project_id={id}` - Objetivos por proyecto
- `POST /api/targets` - Crea un objetivo
- `PUT /api/targets/{id}` - Actualiza un objetivo
- `DELETE /api/targets/{id}` - Elimina un objetivo

#### Ítems de Checklist
- `GET /api/checklist/items` - Lista todos los ítems
- `GET /api/checklist/items?target_id={id}` - Ítems de un objetivo
- `POST /api/checklist/items/{id}/status` - Actualiza estado del ítem

#### Notas
- `GET /api/notes?target_id={id}` - Notas de un objetivo
- `POST /api/notes` - Crea una nota
- `PUT /api/notes/{id}` - Actualiza una nota
- `DELETE /api/notes/{id}` - Elimina una nota

### Ejemplos de API

```bash
# Obtener todos los proyectos
curl http://localhost/api/projects

# Crear un nuevo proyecto
curl -X POST http://localhost/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"Proyecto HackerOne","description":"Testing example.com"}'

# Añadir un objetivo
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"name":"Main Site","type":"url","value":"https://example.com"}'
```

---

## 🛠️ Desarrollo

### Añadir Categorías Personalizadas
Ve a la página de Categorías para crear categorías de prueba personalizadas.

### Extender el Checklist
Puedes añadir ítems personalizados vía phpMyAdmin o API:

```sql
INSERT INTO checklist_items (category_id, description, is_default)
VALUES (1, 'Descripción de prueba de seguridad personalizada', 1);
```

### Triggers de Base de Datos
Se usan triggers MySQL para la agregación automática de notas:
- `after_item_note_insert`
- `after_item_note_update`
- `after_item_note_delete`

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas!

1. Haz fork del repositorio
2. Crea una rama (`git checkout -b feature/NuevaFuncionalidad`)
3. Commits (`git commit -m 'Añade nueva funcionalidad'`)
4. Push (`git push origin feature/NuevaFuncionalidad`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo licencia MIT - ver [LICENSE](LICENSE).

---

## 🙏 Agradecimientos

- Construido con ❤️ para la comunidad de Bug Bounty
- Inspirado en flujos de trabajo reales de pentesting
- Gracias a todos los investigadores que aportaron feedback

---

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/0xRh4ps00dy/bug-bounty-project-manager/issues)
- **Documentación**: [Wiki](https://github.com/0xRh4ps00dy/bug-bounty-project-manager/wiki)

---

<div align="center">

**[⬆ Volver arriba](#-bug-bounty-project-manager)**

Hecho con 🔒 por investigadores de seguridad, para investigadores de seguridad

</div>
