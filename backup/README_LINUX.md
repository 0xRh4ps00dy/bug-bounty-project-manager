# 🔒 Sistema de Copias de Seguridad - Linux

Sistema completo de backup y restauración para Bug Bounty Project Manager en sistemas Linux/Unix.

## 📋 Scripts Disponibles

- **backup.sh** - Script principal para crear backups
- **restore.sh** - Script para restaurar desde backups
- **schedule-backup.sh** - Configurador de backups automáticos con cron
- **backups/** - Directorio donde se almacenan los backups

---

## 🚀 Instalación Rápida

### 1. Hacer scripts ejecutables

```bash
cd /ruta/a/tu/proyecto/backup
chmod +x *.sh
```

### 2. Verificar Docker

```bash
# Verificar que Docker está corriendo
docker ps

# Si necesitas permisos, agrega tu usuario al grupo docker
sudo usermod -aG docker $USER
# Luego cierra sesión y vuelve a iniciar
```

---

## 📦 Uso de Scripts

### Crear Backup Manual

```bash
# Backup con configuración por defecto
./backup.sh

# Personalizar directorio de backups
BACKUP_DIR="/mnt/backups" ./backup.sh

# Cambiar retención (días)
RETENTION_DAYS=30 ./backup.sh

# Combinar opciones
BACKUP_DIR="/mnt/backups" RETENTION_DAYS=14 ./backup.sh
```

### Restaurar Backup

```bash
# Modo interactivo - muestra lista de backups disponibles
./restore.sh

# Restaurar archivo específico
./restore.sh /ruta/al/backup.tar.gz

# Restaurar solo base de datos
./restore.sh --database-only

# Restaurar solo archivos
./restore.sh --files-only

# Restaurar backup específico solo BD
./restore.sh /ruta/al/backup.tar.gz --database-only
```

### Programar Backups Automáticos

```bash
# Backup diario a las 2:00 AM (por defecto)
./schedule-backup.sh

# Backup cada hora
./schedule-backup.sh --frequency hourly

# Backup semanal los domingos a las 3:00 AM
./schedule-backup.sh --frequency weekly --time 03:00

# Backup mensual el día 1 a las 1:00 AM
./schedule-backup.sh --frequency monthly --time 01:00

# Ver ayuda
./schedule-backup.sh --help
```

---

## 📊 ¿Qué se Incluye en el Backup?

### Base de Datos MySQL
- ✅ Todas las tablas con datos completos
- ✅ Procedures, triggers y eventos
- ✅ Estructura y relaciones
- ✅ Exportación con `--single-transaction` (sin bloquear tablas)

### Archivos del Proyecto
- ✅ Carpetas: `www/`, `public/`, `app/`, `config/`, `routes/`, `mysql/`
- ✅ Archivos raíz: `docker-compose.yml`, `composer.json`, etc.
- ✅ Configuraciones y código fuente

### Formato de Archivo
- **Extensión**: `.tar.gz` (comprimido con gzip)
- **Nombre**: `bbpm_backup_YYYY-MM-DD_HH-MM-SS.tar.gz`

---

## ⚙️ Configuración Avanzada

### Variables de Entorno

```bash
# Directorio personalizado para backups
export BACKUP_DIR="/mnt/external/backups"

# Retención personalizada (días)
export RETENTION_DAYS=30

# Usar en scripts
./backup.sh
```

### Configuración Permanente

Agrega a tu `~/.bashrc` o `~/.profile`:

```bash
# Backups BBPM
export BACKUP_DIR="/mnt/backups/bbpm"
export RETENTION_DAYS=14
```

---

## 🕐 Gestión de Cron

### Ver Tareas Programadas

```bash
# Ver todas las tareas cron
crontab -l

# Ver solo tareas de BBPM
crontab -l | grep BBPM
```

### Editar Tareas Manualmente

```bash
crontab -e
```

### Ver Logs de Backups

```bash
# Ver últimas líneas
tail -f backup/backup.log

# Ver todo el log
cat backup/backup.log

# Buscar errores
grep -i error backup/backup.log
```

### Eliminar Backups Automáticos

```bash
# Editar crontab y eliminar línea de BBPM
crontab -e

# O eliminar todas las tareas
crontab -r
```

### Ejemplos de Horarios Cron

```bash
# Cada 6 horas
0 */6 * * * cd /ruta/backup && ./backup.sh >> backup.log 2>&1

# De lunes a viernes a las 23:00
0 23 * * 1-5 cd /ruta/backup && ./backup.sh >> backup.log 2>&1

# Primer día de cada mes a las 00:00
0 0 1 * * cd /ruta/backup && ./backup.sh >> backup.log 2>&1

# Cada 4 horas solo en días laborables
0 */4 * * 1-5 cd /ruta/backup && ./backup.sh >> backup.log 2>&1
```

---

## 🔧 Solución de Problemas

### Error: "Permission denied"

```bash
# Hacer scripts ejecutables
chmod +x backup/*.sh

# Si el problema persiste con Docker
sudo usermod -aG docker $USER
# Cerrar sesión y volver a entrar
```

### Error: "Docker no está disponible"

```bash
# Verificar estado de Docker
sudo systemctl status docker

# Iniciar Docker
sudo systemctl start docker

# Habilitar Docker al inicio
sudo systemctl enable docker
```

### Error: "Contenedor bbpm_mysql no encontrado"

```bash
# Verificar contenedores
docker ps -a

# Iniciar contenedores
cd /ruta/al/proyecto
docker-compose up -d

# Ver logs si hay errores
docker-compose logs
```

### Backup ocupa mucho espacio

```bash
# Ver tamaño de backups
du -sh backup/backups/

# Reducir retención
RETENTION_DAYS=3 ./backup.sh

# Mover a disco externo
mv backup/backups/* /mnt/external/backups/
```

### Cron no ejecuta el backup

```bash
# Verificar que cron está corriendo
sudo systemctl status cron     # Debian/Ubuntu
sudo systemctl status crond    # RHEL/CentOS

# Iniciar cron si está detenido
sudo systemctl start cron

# Ver logs del sistema
sudo grep CRON /var/log/syslog  # Debian/Ubuntu
sudo grep CRON /var/log/cron    # RHEL/CentOS

# Verificar permisos del script
ls -l backup.sh
chmod +x backup.sh
```

---

## 📈 Verificación de Backups

### Listar Backups Existentes

```bash
# Listar con detalles
ls -lh backup/backups/

# Solo nombres
ls backup/backups/*.tar.gz

# Ordenados por fecha (más recientes primero)
ls -lt backup/backups/*.tar.gz | head

# Tamaño total
du -sh backup/backups/
```

### Verificar Integridad de Backup

```bash
# Verificar que el tar.gz es válido
tar -tzf backup/backups/bbpm_backup_2025-12-04_14-30-45.tar.gz

# Ver contenido sin extraer
tar -tzf backup/backups/bbpm_backup_2025-12-04_14-30-45.tar.gz | less

# Verificar archivo SQL dentro del backup
tar -xzOf backup/backups/bbpm_backup_2025-12-04_14-30-45.tar.gz "*/database_*.sql" | head -n 20
```

### Probar Restauración

```bash
# 1. Crear backup actual
./backup.sh

# 2. Hacer cambios de prueba (opcional)
# ...

# 3. Restaurar
./restore.sh

# 4. Verificar aplicación
curl http://localhost
```

---

## 🎯 Mejores Prácticas Linux

### 1. Backups en Disco Externo

```bash
# Montar disco externo
sudo mkdir -p /mnt/backup
sudo mount /dev/sdb1 /mnt/backup

# Ejecutar backup
BACKUP_DIR="/mnt/backup/bbpm" ./backup.sh

# Configurar montaje automático en /etc/fstab
echo "UUID=xxx /mnt/backup ext4 defaults 0 2" | sudo tee -a /etc/fstab
```

### 2. Backups Remotos con rsync

```bash
# Sincronizar backups a servidor remoto
rsync -avz --progress backup/backups/ usuario@servidor:/ruta/remota/backups/

# Agregar a cron después del backup
# En crontab -e:
0 3 * * * cd /ruta/backup && ./backup.sh && rsync -az backups/ user@remote:/backups/
```

### 3. Notificaciones por Email

Instalar mailutils:

```bash
sudo apt install mailutils  # Debian/Ubuntu
sudo yum install mailx      # RHEL/CentOS
```

Modificar `backup.sh` para agregar al final:

```bash
echo "Backup completado: $ZIP_FILE" | mail -s "BBPM Backup OK" tu@email.com
```

### 4. Monitoreo con Scripts

```bash
#!/bin/bash
# check-backups.sh - Verificar que hay backups recientes

BACKUP_DIR="/ruta/a/backups"
MAX_AGE_HOURS=26  # Alerta si no hay backup en 26 horas

LATEST=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mmin -$((MAX_AGE_HOURS * 60)) | wc -l)

if [ "$LATEST" -eq 0 ]; then
    echo "ALERTA: No hay backups recientes de BBPM" | mail -s "BBPM Backup Alert" admin@example.com
fi
```

---

## 🔐 Seguridad

### Permisos Recomendados

```bash
# Directorio de backups solo para usuario y root
chmod 700 backup/backups/

# Scripts ejecutables solo por usuario
chmod 700 backup/*.sh

# Verificar permisos
ls -la backup/
```

### Encriptación de Backups (Opcional)

```bash
# Encriptar backup con GPG
gpg --symmetric --cipher-algo AES256 backup.tar.gz

# Desencriptar
gpg backup.tar.gz.gpg
```

### Backups Offsite

```bash
# Subir a S3 (requiere aws-cli)
aws s3 cp backup/backups/bbpm_backup_*.tar.gz s3://mi-bucket/backups/

# Subir a Google Drive (con rclone)
rclone copy backup/backups/ gdrive:BBPM_Backups/
```

---

## 📱 Integración con Systemd (Alternativa a Cron)

### Crear servicio y timer

```bash
# /etc/systemd/system/bbpm-backup.service
[Unit]
Description=BBPM Backup Service
After=docker.service

[Service]
Type=oneshot
User=tu_usuario
WorkingDirectory=/ruta/a/proyecto/backup
ExecStart=/ruta/a/proyecto/backup/backup.sh
StandardOutput=append:/ruta/a/proyecto/backup/backup.log
StandardError=append:/ruta/a/proyecto/backup/backup.log

# /etc/systemd/system/bbpm-backup.timer
[Unit]
Description=BBPM Backup Timer
Requires=bbpm-backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target

# Habilitar y iniciar
sudo systemctl enable bbpm-backup.timer
sudo systemctl start bbpm-backup.timer

# Ver estado
sudo systemctl status bbpm-backup.timer
```

---

## 📞 Comandos de Referencia Rápida

```bash
# Backup manual
./backup.sh

# Restaurar interactivo
./restore.sh

# Programar diario
./schedule-backup.sh

# Ver backups
ls -lh backups/

# Ver logs
tail -f backup.log

# Verificar cron
crontab -l

# Tamaño de backups
du -sh backups/

# Backup más reciente
ls -t backups/*.tar.gz | head -1

# Contar backups
ls backups/*.tar.gz | wc -l

# Eliminar backups >30 días
find backups/ -name "*.tar.gz" -mtime +30 -delete
```

---

## 🆘 Recuperación de Emergencia

### Desastre Completo

```bash
# 1. Clonar repositorio
git clone <repo-url>
cd bug-bounty-project-manager

# 2. Iniciar contenedores
docker-compose up -d

# 3. Restaurar desde backup
cd backup
./restore.sh /ruta/al/backup.tar.gz

# 4. Verificar
docker-compose ps
curl http://localhost
```

### Solo Base de Datos Corrupta

```bash
./restore.sh --database-only
docker-compose restart db
```

### Solo Archivos Perdidos

```bash
./restore.sh --files-only
```

---

## 📌 Diferencias con Windows (PowerShell)

| Característica | Linux (Bash) | Windows (PowerShell) |
|---|---|---|
| **Extensión** | `.sh` | `.ps1` |
| **Compresión** | `.tar.gz` | `.zip` |
| **Programación** | cron | Task Scheduler |
| **Permisos** | `chmod +x` | Execution Policy |
| **Logs** | `>>` | `Out-File` |
| **Variables** | `export VAR=value` | `$env:VAR="value"` |

---

**¡Tu proyecto en Linux está protegido! 🐧🛡️**
