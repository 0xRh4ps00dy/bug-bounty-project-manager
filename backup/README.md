# 🔒 Sistema de Copias de Seguridad

Sistema completo de backup y restauración para Bug Bounty Project Manager.

## 📋 Contenido

- **backup.ps1** - Script principal para crear backups
- **restore.ps1** - Script para restaurar desde backups
- **schedule-backup.ps1** - Configurador de backups automáticos
- **backups/** - Directorio donde se almacenan los backups

---

## 🚀 Uso Rápido

### Crear Backup Manual

```powershell
.\backup.ps1
```

### Restaurar Backup

```powershell
# Muestra lista de backups disponibles
.\restore.ps1

# Restaurar archivo específico
.\restore.ps1 -BackupFile "C:\ruta\al\backup.zip"

# Restaurar solo base de datos
.\restore.ps1 -DatabaseOnly

# Restaurar solo archivos
.\restore.ps1 -FilesOnly
```

### Programar Backups Automáticos

```powershell
# Backup diario a las 2:00 AM (requiere PowerShell como Administrador)
.\schedule-backup.ps1

# Backup cada hora
.\schedule-backup.ps1 -Frequency Hourly

# Backup semanal los domingos a las 3:00 AM
.\schedule-backup.ps1 -Frequency Weekly -Time "03:00"
```

---

## 📦 ¿Qué se Incluye en el Backup?

### Base de Datos
- ✅ Todas las tablas (usuarios, proyectos, targets, checklist, etc.)
- ✅ Datos completos
- ✅ Procedures, triggers y eventos
- ✅ Estructura y relaciones

### Archivos del Proyecto
- ✅ `www/` - Archivos PHP antiguos
- ✅ `public/` - Frontend y assets
- ✅ `app/` - Lógica de negocio
- ✅ `config/` - Configuración
- ✅ `routes/` - Rutas de la API
- ✅ `mysql/` - Scripts de inicialización
- ✅ Archivos raíz importantes (docker-compose.yml, composer.json, etc.)

---

## ⚙️ Configuración Avanzada

### Cambiar Directorio de Backups

```powershell
.\backup.ps1 -BackupDir "D:\MisBackups\BBPM"
```

### Cambiar Retención de Backups

Por defecto, los backups se mantienen por **7 días**. Para cambiar:

```powershell
# Mantener backups por 30 días
.\backup.ps1 -RetentionDays 30

# Mantener backups indefinidamente
.\backup.ps1 -RetentionDays 999999
```

---

## 📊 Estructura de un Backup

```
bbpm_backup_2025-12-04_14-30-45.zip
├── database_2025-12-04_14-30-45.sql
└── files/
    ├── www/
    ├── public/
    ├── app/
    ├── config/
    ├── routes/
    ├── mysql/
    ├── docker-compose.yml
    ├── composer.json
    └── composer.lock
```

---

## 🔧 Solución de Problemas

### Error: "Docker no está disponible"

**Solución**: Inicia Docker Desktop antes de ejecutar los scripts.

```powershell
# Verificar estado de Docker
docker ps
```

### Error: "Permiso denegado"

**Solución**: Para schedule-backup.ps1, ejecuta PowerShell como Administrador.

```powershell
# Clic derecho en PowerShell > "Ejecutar como administrador"
```

### Los backups ocupan mucho espacio

**Solución**: Reduce el tiempo de retención o almacena backups en otro disco.

```powershell
# Guardar en disco D: y mantener solo 3 días
.\backup.ps1 -BackupDir "D:\Backups" -RetentionDays 3
```

### Error al restaurar base de datos

**Verificaciones**:
1. Contenedor MySQL está corriendo: `docker ps | Select-String "bbpm_mysql"`
2. Credenciales correctas en docker-compose.yml
3. Archivo SQL no está corrupto

---

## 📝 Verificación de Backups

### Verificar Backups Existentes

```powershell
# Listar todos los backups
Get-ChildItem .\backups\*.zip | Format-Table Name, Length, LastWriteTime

# Ver tamaño total
(Get-ChildItem .\backups\*.zip | Measure-Object -Property Length -Sum).Sum / 1MB
```

### Probar Restauración (Entorno de Prueba)

```powershell
# 1. Crear backup actual
.\backup.ps1

# 2. Hacer cambios en base de datos o archivos

# 3. Restaurar desde backup
.\restore.ps1

# 4. Verificar que todo está como antes
```

---

## 🔄 Gestión de Tareas Programadas

### Ver Estado de Tarea Automática

```powershell
Get-ScheduledTask -TaskName "BBPM_AutoBackup" | Format-List
```

### Ejecutar Backup Manualmente Desde Tarea

```powershell
Start-ScheduledTask -TaskName "BBPM_AutoBackup"
```

### Ver Historial de Ejecuciones

```powershell
Get-ScheduledTaskInfo -TaskName "BBPM_AutoBackup"
```

### Deshabilitar Backups Automáticos

```powershell
Disable-ScheduledTask -TaskName "BBPM_AutoBackup"
```

### Eliminar Tarea Programada

```powershell
Unregister-ScheduledTask -TaskName "BBPM_AutoBackup" -Confirm:$false
```

---

## 🎯 Mejores Prácticas

1. **Prueba tus backups regularmente** - Restaura en un entorno de prueba mensualmente
2. **Almacena backups fuera del servidor** - Copia a disco externo o nube
3. **Documenta cambios importantes** - Anota modificaciones grandes antes de hacerlas
4. **Verifica el espacio en disco** - Asegúrate de tener espacio suficiente
5. **Mantén múltiples versiones** - No confíes en un solo backup

---

## 📅 Estrategia de Backup Recomendada

### Para Desarrollo
- **Frecuencia**: Diaria (antes de cambios importantes)
- **Retención**: 7 días
- **Horario**: 2:00 AM

### Para Producción
- **Frecuencia**: Cada 6 horas
- **Retención**: 30 días
- **Backup externo**: Semanal
- **Horarios**: 02:00, 08:00, 14:00, 20:00

---

## 🆘 Recuperación de Emergencia

### Escenario 1: Base de Datos Corrupta

```powershell
# Restaurar solo base de datos
.\restore.ps1 -DatabaseOnly
```

### Escenario 2: Archivos Eliminados Accidentalmente

```powershell
# Restaurar solo archivos
.\restore.ps1 -FilesOnly
```

### Escenario 3: Desastre Completo

```powershell
# 1. Reiniciar contenedores
docker-compose down
docker-compose up -d

# 2. Restaurar todo
.\restore.ps1

# 3. Verificar servicios
docker ps
```

---

## 📞 Soporte

Si encuentras problemas:
1. Revisa los logs de Docker: `docker-compose logs`
2. Verifica permisos de archivos
3. Asegúrate de tener espacio en disco suficiente
4. Comprueba que Docker Desktop está corriendo

---

## 🔐 Seguridad

- ⚠️ Los backups contienen datos sensibles (contraseñas, tokens, etc.)
- 🔒 Almacénalos en ubicaciones seguras
- 🚫 No subas backups a repositorios públicos
- 🔑 Considera encriptar backups para producción

---

## 📌 Notas Importantes

- Los scripts requieren **PowerShell 5.1 o superior**
- El sistema debe tener **Docker instalado y corriendo**
- Los contenedores deben estar activos (`docker-compose up -d`)
- Se recomienda **ejecutar como Administrador** para schedule-backup.ps1
- La restauración **sobrescribe datos actuales** - usa con precaución

---

## 📈 Próximas Mejoras

- [ ] Encriptación de backups
- [ ] Upload automático a cloud (AWS S3, Google Drive)
- [ ] Notificaciones por email
- [ ] Dashboard de monitoreo de backups
- [ ] Compresión diferencial
- [ ] Backup incremental

---

**¡Tu proyecto está protegido! 🛡️**
