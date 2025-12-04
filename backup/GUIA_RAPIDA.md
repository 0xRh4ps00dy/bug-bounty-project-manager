# 🔒 Guía Rápida de Backups - BBPM

## ⚡ Inicio Rápido

### Windows (PowerShell)
```powershell
cd backup
.\bbpm-backup.ps1
```

### Linux (Bash)
```bash
cd backup
chmod +x bbpm-backup.sh
./bbpm-backup.sh
```

¡Eso es todo! El menú interactivo te guiará paso a paso.

---

## 📋 Menú Principal

```
╔═══════════════════════════════════════════════════════════╗
║       🔒 BBPM BACKUP MANAGER - Sistema Simplificado      ║
╚═══════════════════════════════════════════════════════════╝

  1. 💾 Crear Backup
  2. ♻️  Restaurar Backup
  3. 📋 Ver Backups
  4. ⏰ Configurar Automático
  5. ❌ Salir
```

---

## 🎯 Casos de Uso

### 1️⃣ Crear un Backup

**Cuándo usarlo:**
- Antes de hacer cambios importantes
- Antes de actualizar el sistema
- Como backup regular manual

**Cómo:**
1. Selecciona opción `1`
2. Espera unos segundos
3. ¡Listo! Tu backup está guardado

**¿Qué incluye?**
- ✅ Base de datos completa
- ✅ Todos los archivos del proyecto
- ✅ Configuraciones

---

### 2️⃣ Restaurar un Backup

**Cuándo usarlo:**
- Algo salió mal y necesitas volver atrás
- Recuperar datos perdidos
- Migrar a otro servidor

**Cómo:**
1. Selecciona opción `2`
2. Elige el backup de la lista
3. Escribe `SI` para confirmar
4. ¡Restaurado!

**⚠️ Advertencia:** Sobrescribirá los datos actuales

---

### 3️⃣ Ver Backups

**Para qué:**
- Ver cuántos backups tienes
- Comprobar fechas y tamaños
- Verificar espacio usado

**Muestra:**
- 📦 Nombre del backup
- 📅 Fecha de creación
- 💾 Tamaño
- ⏰ Antigüedad (días)

---

### 4️⃣ Configurar Automático

**Opciones disponibles:**

| Opción | Frecuencia | Ideal para |
|--------|-----------|------------|
| 1 | Diario 2:00 AM | Desarrollo |
| 2 | Cada 12 horas | Proyectos activos |
| 3 | Cada 6 horas | Producción |
| 4 | Semanal (Domingo) | Proyectos pequeños |
| 5 | Desactivar | - |

**Windows:** Requiere PowerShell como Administrador  
**Linux:** Configura crontab automáticamente

---

## 🚀 Comandos Directos (Sin Menú)

### Windows
```powershell
# Crear backup directo
.\bbpm-backup.ps1 backup

# Restaurar directo
.\bbpm-backup.ps1 restore

# Ver lista
.\bbpm-backup.ps1 list

# Configurar automático
.\bbpm-backup.ps1 auto
```

### Linux
```bash
# Crear backup directo
./bbpm-backup.sh backup

# Restaurar directo
./bbpm-backup.sh restore

# Ver lista
./bbpm-backup.sh list

# Configurar automático
./bbpm-backup.sh auto
```

---

## 📁 ¿Dónde se Guardan los Backups?

```
backup/
├── backups/                    # ← Aquí están tus backups
│   ├── bbpm_backup_2025-12-04_14-30-45.zip (Windows)
│   └── bbpm_backup_2025-12-04_14-30-45.tar.gz (Linux)
├── bbpm-backup.ps1            # Script Windows
├── bbpm-backup.sh             # Script Linux
└── GUIA_RAPIDA.md            # Esta guía
```

---

## ⏱️ ¿Cuánto Tiempo Toman?

| Operación | Tiempo aproximado |
|-----------|------------------|
| Crear backup | 10-30 segundos |
| Restaurar backup | 20-40 segundos |
| Ver backups | Instantáneo |
| Configurar automático | 5 segundos |

---

## 💡 Consejos Rápidos

### ✅ HACER
- ✅ Crear backup antes de cambios importantes
- ✅ Revisar backups semanalmente
- ✅ Configurar backups automáticos
- ✅ Guardar backups importantes en otro disco/USB

### ❌ NO HACER
- ❌ Restaurar sin confirmar que es el backup correcto
- ❌ Eliminar todos los backups manualmente
- ❌ Ejecutar backup mientras hay actualizaciones

---

## 🔧 Solución de Problemas

### "Docker no está corriendo"
**Solución:** Inicia Docker Desktop

```powershell
# Windows: Buscar "Docker Desktop" en menú inicio
```

### "Contenedor no encontrado"
**Solución:** Inicia los contenedores

```bash
cd ..  # Volver al directorio principal
docker-compose up -d
```

### "Sin permisos" (Linux)
**Solución:** Agregar tu usuario al grupo docker

```bash
sudo usermod -aG docker $USER
# Cerrar sesión y volver a entrar
```

### "Sin permisos" (Windows - Auto)
**Solución:** Ejecutar PowerShell como Administrador
- Clic derecho en PowerShell
- "Ejecutar como administrador"

---

## 📊 Retención de Backups

**Automática:** Los backups de más de 7 días se eliminan automáticamente

**Cambiar retención:**
- Edita el script si necesitas mantenerlos más tiempo
- O copia los backups importantes a otra ubicación

---

## 🎓 Ejemplo Completo - Caso Real

### Escenario: Vas a actualizar la base de datos

```powershell
# 1. Crear backup de seguridad
cd backup
.\bbpm-backup.ps1 backup

# 2. Hacer tus cambios
cd ..
# ... realizar actualizaciones ...

# 3. ¿Algo salió mal? Restaurar
cd backup
.\bbpm-backup.ps1 restore
# Seleccionar el backup más reciente
# Escribir "SI" para confirmar

# ¡Listo! Todo vuelve al estado anterior
```

---

## 📞 Referencia Rápida

| Necesito... | Selecciono... |
|-------------|---------------|
| Guardar estado actual | Opción 1 - Crear Backup |
| Volver a un punto anterior | Opción 2 - Restaurar |
| Ver qué backups tengo | Opción 3 - Ver Backups |
| Automatizar backups | Opción 4 - Configurar Auto |
| Hacer backup sin menú | `bbpm-backup backup` |

---

## 🌟 Características Principales

| Característica | Descripción |
|----------------|-------------|
| **🎨 Interfaz Visual** | Menú con colores y emojis |
| **⚡ Super Rápido** | Backups en segundos |
| **🔒 Seguro** | Confirmación antes de restaurar |
| **🤖 Automático** | Programación de backups |
| **📦 Compacto** | Compresión automática |
| **🧹 Auto-limpieza** | Elimina backups antiguos |
| **🔄 Multiplataforma** | Windows y Linux |
| **📱 Sin dependencias** | Solo Docker necesario |

---

## 🎉 ¡Y eso es todo!

**Sistema simplificado y fácil de usar.**

No necesitas recordar comandos complicados, solo ejecuta el script y sigue el menú.

**¿Dudas?** Lee los README.md detallados en la carpeta backup.

**¡Tus datos están protegidos! 🛡️**
