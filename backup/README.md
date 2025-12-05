# Sistema de Copias de Seguridad - Bug Bounty Project Manager

Sistema simplificado para realizar copias de seguridad y restaurar la base de datos MySQL.

## 📋 Scripts disponibles

### 1. **backup.sh** - Backup Manual
Realiza una copia de seguridad manual de la base de datos.

```bash
./backup/backup.sh
```

**Características:**
- ✅ Crea un archivo SQL comprimido con timestamp
- ✅ Mantiene un historial de backups
- ✅ Elimina automáticamente backups más antiguos de 30 días
- ✅ Muestra los últimos backups realizados

**Ejemplo:**
```
Starting database backup...
✓ Backup completed successfully!
File: backup/backups/bbpm_backup_20251205_120000.sql.gz
Size: 256K
```

### 2. **restore.sh** - Restaurar Backup
Restaura la base de datos desde un archivo de backup.

```bash
./backup/restore.sh backup/backups/bbpm_backup_20251205_120000.sql.gz
```

**Características:**
- ✅ Solicita confirmación antes de restaurar
- ✅ Soporta archivos comprimidos (.gz) y sin comprimir
- ✅ Verifica que el archivo exista

### 3. **auto-backup.sh** - Backup Automático
Script para ejecutar backups automáticos desde cron.

**Uso en crontab:**
```bash
# Backup diario a las 2:00 AM
0 2 * * * /path/to/project/backup/auto-backup.sh

# Backup cada 6 horas
0 */6 * * * /path/to/project/backup/auto-backup.sh
```

**Características:**
- ✅ Lee variables del `.env` automáticamente
- ✅ Comprime el backup automáticamente
- ✅ Mantiene un log en `backup/backups/backup.log`
- ✅ Elimina automáticamente backups antiguos (últimos 7 días)

## ⚙️ Configuración

Los scripts usan las variables del `.env`:
```env
DB_HOST=db
DB_PORT=3306
DB_NAME=bbpm_db
DB_USER=bbpm_user
DB_PASS=bbpm_password
```

## 📁 Estructura

```
backup/
├── backups/              # Directorio con los backups
│   ├── backup.log       # Log de backups automáticos
│   ├── bbpm_backup_*.sql.gz
│   └── .gitkeep
├── backup.sh             # Script de backup manual
├── restore.sh            # Script de restauración
├── auto-backup.sh        # Script para cron
└── README.md
```

## 🔧 Primeros pasos

1. **Dar permisos de ejecución:**
```bash
chmod +x backup/backup.sh
chmod +x backup/restore.sh
chmod +x backup/auto-backup.sh
```

2. **Hacer un backup manual:**
```bash
./backup/backup.sh
```

3. **Configurar backup automático (opcional):**
```bash
crontab -e
# Agregar línea para backup diario
```

## 🔐 Seguridad

- El archivo `.env` no se versionan
- Cambiar las contraseñas por defecto
- Proteger la carpeta `backup/backups/`
- Considerar backups en servidor externo

## ❓ Troubleshooting

**Error: "command not found"**
```bash
chmod +x backup/*.sh
```

**Error: "Access denied"**
```bash
cat .env | grep DB_  # Verificar credenciales
```
./backup/backup-database.sh

# Backup con configuración personalizada
./backup/backup-database.sh "./backup/backups" 14 gzip
```

#### Restaurar desde un backup:
```bash
# Restauración interactiva (pedirá confirmación)
chmod +x ./backup/restore-database.sh
./backup/restore-database.sh "./backup/backups/bbpm_db_2024-01-15_10-30-45.sql.gz"

# Restauración forzada (sin confirmación)
./backup/restore-database.sh "./backup/backups/bbpm_db_2024-01-15_10-30-45.sql.gz" db root root_password bbpm_db force
```

## ⚙️ Configuración

### Parámetros de Backup

| Parámetro | Descripción | Valor por defecto |
|-----------|-------------|-------------------|
| `BackupDir` | Directorio donde guardar backups | `./backup/backups` |
| `RetentionDays` | Días que se conservan los backups | `7` |
| `CompressionFormat` | Formato de compresión (gzip o zip) | `gzip` |

### Parámetros de Restauración

| Parámetro | Descripción | Valor por defecto |
|-----------|-------------|-------------------|
| `BackupFile` | Ruta al archivo de backup | Requerido |
| `DbHost` | Host de la base de datos | `db` |
| `DbUser` | Usuario de MySQL | `root` |
| `DbPassword` | Contraseña de MySQL | `root_password` |
| `DbName` | Nombre de la base de datos | `bbpm_db` |
| `Force` | Forzar restauración sin confirmación | `false` |

## 📅 Automatización

### Windows (Task Scheduler)

Para crear una tarea programada en Windows:

1. Abre "Programador de tareas" (Task Scheduler)
2. Crea una nueva tarea básica
3. Nombre: "BBPM Database Backup"
4. Disparador: Diario a las 2:00 AM (o la hora que prefieras)
5. Acción: Iniciar un programa
   - Programa: `powershell.exe`
   - Argumentos: `-ExecutionPolicy Bypass -File "C:\ruta\backup\backup-database.ps1"`
6. Configura según sea necesario

### Linux/Mac (Cron)

Para automatizar backups diarios a las 2:00 AM:

```bash
# Editar crontab
crontab -e

# Agregar la siguiente línea (ajusta la ruta según sea necesario)
0 2 * * * cd /ruta/bug-bounty-project-manager && ./backup/backup-database.sh
```

## 📊 Ejemplos de Output

### Backup exitoso:
```
[*] Iniciando backup de la base de datos: bbpm_db
[*] Timestamp: 2024-01-15_10-30-45
[✓] Backup completado exitosamente
    Archivo: bbpm_db_2024-01-15_10-30-45.sql
    Tamaño: 5.42 MB
    Ruta: ./backup/backups/bbpm_db_2024-01-15_10-30-45.sql
[*] Comprimiendo archivo con gzip...
[✓] Archivo comprimido
    Archivo: bbpm_db_2024-01-15_10-30-45.sql.gz
    Tamaño comprimido: 0.85 MB
[*] Limpiando backups antiguos (retención: 7 días)...
[✓] Backups antiguos eliminados
[✓] Proceso de backup completado
```

### Restauración exitosa:
```
[*] Preparando restauración de backup
    Archivo: bbpm_db_2024-01-15_10-30-45.sql.gz
    Tamaño: 0.85 MB
    Base de datos: bbpm_db
[*] Descomprimiendo archivo...
[✓] Archivo descomprimido
[*] Restaurando base de datos...
[✓] Restauración completada exitosamente
    Base de datos: bbpm_db
    Datos restaurados desde: bbpm_db_2024-01-15_10-30-45.sql.gz
[✓] Proceso de restauración completado
```

## ⚠️ Notas Importantes

1. **Validar backups regularmente**: Periódicamente verifica que los backups se crean correctamente
2. **Probar restauraciones**: Es recomendable hacer pruebas de restauración en ambiente de staging
3. **Mantener múltiples copias**: Considera guardar backups en ubicaciones remotas o en la nube
4. **Monitorear el espacio**: Asegúrate de que haya suficiente espacio en disco para los backups
5. **Contraseñas seguras**: Cambia las contraseñas por defecto en los scripts de producción

## 🔒 Seguridad

- Los archivos de backup contienen datos sensibles
- Asegúrate de tener permisos de acceso restrictivos en la carpeta `backups/`
- Considera encriptar los backups antes de enviarlos a almacenamiento remoto
- Nunca compartas credenciales de base de datos en repositorios públicos

## 📞 Soporte

Para problemas o mejoras, consulta la documentación de MySQL o contacta con el equipo de desarrollo.

---

**Última actualización:** 2024-12-04
**Versión:** 1.0
