# LAMP Stack amb Docker Compose

Aquest projecte conté un stack LAMP (Linux, Apache, MySQL, PHP) completament funcional amb Docker Compose.

## Components

- **Apache + PHP 8.2**: Servidor web amb PHP
- **MySQL 8.0**: Base de dades
- **phpMyAdmin**: Interfície web per gestionar MySQL

## Ús

### Iniciar els contenidors:
```bash
docker-compose up -d
```

### Aturar els contenidors:
```bash
docker-compose down
```

### Veure els logs:
```bash
docker-compose logs -f
```

### Accedir als serveis:
- **Aplicació web**: http://localhost
- **phpMyAdmin**: http://localhost:8080
  - Usuari: `lamp_user`
  - Contrasenya: `lamp_password`
  - O com a root: `root` / `root_password`

## Estructura del projecte

```
.
├── docker-compose.yml      # Configuració dels serveis
├── apache/
│   └── Dockerfile         # Imatge personalitzada d'Apache + PHP
├── mysql/
│   └── init.sql          # Script d'inicialització de la BD
└── www/
    └── index.php         # Fitxers de l'aplicació web
```

## Credencials de MySQL

- **Root Password**: `root_password`
- **Database**: `lamp_db`
- **User**: `lamp_user`
- **Password**: `lamp_password`

## Notes

- Els fitxers PHP s'han de col·locar a la carpeta `www/`
- Les dades de MySQL es guarden en un volum persistent (`mysql_data`)
- Per connectar-te a MySQL des de PHP, utilitza `db` com a host
- El script `init.sql` s'executa automàticament en la primera inicialització

## Requisits

- Docker
- Docker Compose

## Resolució de problemes

Si el port 80 o 3306 ja està en ús, pots modificar els ports al fitxer `docker-compose.yml`.
