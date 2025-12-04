# Sistema de Backup de Base de Datos - Bug Bounty Project Manager

Este directorio contiene scripts para realizar backups y restauraciones de la base de datos MySQL.

## 📋 Contenido

- `backup-database.ps1` - Script de backup para Windows (PowerShell)
- `backup-database.sh` - Script de backup para Linux/Mac (Bash)
- `restore-database.ps1` - Script de restauración para Windows (PowerShell)
- `restore-database.sh` - Script de restauración para Linux/Mac (Bash)
- `backups/` - Directorio donde se almacenan los archivos de backup

## 🔄 Características

✅ **Backup automático** de la base de datos MySQL
✅ **Compresión gzip** automática para ahorrar espacio
✅ **Limpieza automática** de backups antiguos (configurables días de retención)
✅ **Restauración rápida** desde cualquier backup
✅ **Manejo de errores** y validaciones
✅ **Output colorido** para mejor legibilidad
✅ **Compatible** con Windows (PowerShell) y Linux/Mac (Bash)

## 📱 Uso

### Windows (PowerShell)

#### Crear un backup:
```powershell
# Backup básico (retención de 7 días)
.\backup\backup-database.ps1

# Backup con configuración personalizada
.\backup\backup-database.ps1 -BackupDir "./backup/backups" -RetentionDays 14 -CompressionFormat gzip
```

#### Restaurar desde un backup:
```powershell
# Restauración interactiva (pedirá confirmación)
.\backup\restore-database.ps1 -BackupFile "./backup/backups/bbpm_db_2024-01-15_10-30-45.sql.gz"

# Restauración forzada (sin confirmación)
.\backup\restore-database.ps1 -BackupFile "./backup/backups/bbpm_db_2024-01-15_10-30-45.sql.gz" -Force
```

### Linux/Mac (Bash)

#### Crear un backup:
```bash
# Backup básico (retención de 7 días)
chmod +x ./backup/backup-database.sh
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
