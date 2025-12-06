# 🗂️ Guía de Uso - Scripts de Backup y MySQL

## 📋 Contenidos

Este directorio contiene scripts para gestionar backups y acceso a la base de datos MySQL.

### 🔧 Scripts Disponibles

#### 1. `backup.sh` - Crear Backup de la Base de Datos
Realiza un backup completo de todas las bases de datos del contenedor MySQL.

**Uso:**
```bash
# Usar contenedor por defecto (bbpm_mysql)
./backup/backup.sh

# Especificar contenedor específico
./backup/backup.sh mi_contenedor_mysql
```

**Características:**
- ✅ Backup de todas las bases de datos
- ✅ Transacciones seguras (--single-transaction)
- ✅ Compresión automática con gzip
- ✅ Timestamp automático en el nombre del archivo
- ✅ Listado de últimos backups

**Ejemplo de salida:**
```
🔄 Iniciando backup de la base de datos...
📦 Contenedor: bbpm_mysql
💾 Base de datos: bbpm_db
✅ Backup completado exitosamente
📦 Tamaño del archivo: 2.5M
📂 Ubicación: ./backup/backups/bbpm_db_20240115_143022.sql.gz
```

---

#### 2. `restore.sh` - Restaurar Backup de la Base de Datos
Restaura la base de datos desde un archivo de backup.

**Uso:**
```bash
# Restaurar desde archivo comprimido
./backup/restore.sh ./backup/backups/bbpm_db_20240115_143022.sql.gz

# Restaurar especificando contenedor
./backup/restore.sh ./backup/backups/bbpm_db_20240115_143022.sql.gz bbpm_mysql
```

**Características:**
- ✅ Soporte para archivos comprimidos (.gz)
- ✅ Soporte para archivos SQL sin comprimir
- ✅ Verificación de existencia del archivo
- ✅ Validación del contenedor

⚠️ **Advertencia:** La restauración reemplazará los datos actuales de la base de datos.

---

#### 3. `connect.sh` - Conectarse a MySQL
Abre una sesión interactiva de MySQL en el contenedor.

**Uso:**
```bash
# Conectar como root
./backup/connect.sh root

# Conectar como usuario bbpm_user
./backup/connect.sh bbpm_user

# Conectar como root a contenedor específico
./backup/connect.sh root mi_contenedor_mysql
```

**Usuarios disponibles:**
- `root` - Administrador total
- `bbpm_user` - Usuario de aplicación

**Ejemplo de sesión:**
```bash
$ ./backup/connect.sh root
🔗 Conectando a MySQL...
👤 Usuario: root
📦 Contenedor: bbpm_mysql

mysql> SHOW DATABASES;
mysql> USE bbpm_db;
mysql> SHOW TABLES;
```

---

## 🔐 Acceso Root y Usuario

### Variables de Entorno

El acceso a MySQL se configura mediante variables en el archivo `.env`:

```env
# Usuario administrador
DB_ROOT_PASSWORD=root_password

# Usuario de aplicación
DB_USER=bbpm_user
DB_PASS=bbpm_password
```

### Formas de Acceso

#### 1️⃣ Desde phpMyAdmin (Recomendado - GUI)
```
URL: http://localhost:8080
Usuario: root
Contraseña: root_password
```

#### 2️⃣ Desde Terminal (CLI)
```bash
# Como root
./backup/connect.sh root

# Como usuario bbpm_user
./backup/connect.sh bbpm_user
```

#### 3️⃣ Desde Docker CLI directamente
```bash
# Como root
docker exec -it bbpm_mysql mysql -u root -proot_password

# Como usuario bbpm_user
docker exec -it bbpm_mysql mysql -u bbpm_user -pbbpm_password
```

---

## 📅 Recomendaciones de Backup

### Estrategia Diaria
```bash
# Crear backup diario (agregar a crontab)
0 2 * * * cd /ruta/proyecto && ./backup/backup.sh

# Esto ejecutará el backup cada día a las 2:00 AM
```

### Verificar Backups Existentes
```bash
ls -lh ./backup/backups/
```

### Retención de Backups
Se recomienda mantener:
- ✅ Último backup de cada día (últimos 7 días)
- ✅ Último backup de cada semana (últimas 4 semanas)
- ✅ Último backup de cada mes (últimos 12 meses)

---

## 🔒 Seguridad

### Cambiar Contraseñas

**1. Cambiar contraseña de root:**
```sql
-- Conectar como root primero
./backup/connect.sh root

-- Ejecutar en MySQL:
ALTER USER 'root'@'localhost' IDENTIFIED BY 'nueva_contraseña';
FLUSH PRIVILEGES;
```

**2. Cambiar contraseña de usuario bbpm_user:**
```sql
ALTER USER 'bbpm_user'@'%' IDENTIFIED BY 'nueva_contraseña';
FLUSH PRIVILEGES;
```

### Actualizar Variables de Entorno
Después de cambiar contraseñas, actualizar `.env`:
```env
DB_ROOT_PASSWORD=nueva_contraseña
DB_PASS=nueva_contraseña
```

Luego reiniciar contenedores:
```bash
docker-compose restart
```

---

## 🐛 Troubleshooting

### Error: "No such container"
```bash
# Verificar nombre del contenedor
docker ps | grep mysql

# Usar el nombre correcto en los scripts
./backup/backup.sh nombre_contenedor_correcto
```

### Error: "Access denied"
```bash
# Verificar contraseña en .env
cat .env | grep DB_

# Reiniciar contenedores si cambiaste contraseña
docker-compose restart
```

### Error: "File not found"
```bash
# Los scripts deben ejecutarse desde el directorio raíz del proyecto
cd /ruta/al/proyecto
./backup/backup.sh
```

---

## 📊 Información Útil de MySQL

### Comandos Comunes dentro de MySQL

```sql
-- Ver todas las bases de datos
SHOW DATABASES;

-- Usar una base de datos específica
USE bbpm_db;

-- Ver tablas
SHOW TABLES;

-- Ver información de tabla
DESCRIBE nombre_tabla;

-- Exportar datos
SELECT * FROM nombre_tabla INTO OUTFILE '/tmp/datos.txt';

-- Ver usuarios
SELECT user, host FROM mysql.user;

-- Ver permisos de usuario
SHOW GRANTS FOR 'bbpm_user'@'%';
```

---

## ✅ Checklist de Configuración

- [x] Archivo `.env` configurado
- [x] Directorio `./backup/backups/` creado
- [x] Scripts de backup ejecutables
- [x] phpMyAdmin accesible
- [x] Acceso por terminal funcional
- [ ] Configurar backups automáticos en crontab
- [ ] Probar restauración de backup
- [ ] Documentar contraseñas en lugar seguro

---

**Última actualización:** Diciembre 2025
**Versión:** 1.0
