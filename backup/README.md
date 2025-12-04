# 🔒 BBPM Backup Manager

## ⚡ Uso Rápido

### Windows
```powershell
.\bbpm-backup.ps1
```

### Linux
```bash
chmod +x bbpm-backup.sh
./bbpm-backup.sh
```

## 📋 Opciones del Menú

1. **Crear Backup** - Guarda BD + archivos
2. **Restaurar Backup** - Recupera desde backup
3. **Ver Backups** - Lista con tamaños y fechas
4. **Configurar Automático** - Backup programado
5. **Salir**

## 🎯 Casos Rápidos

**Crear backup sin menú:**
```powershell
.\bbpm-backup.ps1 backup
```

**Restaurar sin menú:**
```powershell
.\bbpm-backup.ps1 restore
```

**Ver backups:**
```powershell
.\bbpm-backup.ps1 list
```

## 📁 Archivos

- `bbpm-backup.ps1` - Script para Windows
- `bbpm-backup.sh` - Script para Linux
- `.gitignore` - Excluir backups de git

## 💾 Almacenamiento

Los backups se guardan en: `backup/backups/`

Auto-eliminación: Más de 7 días se borran automáticamente.

---

**¡Eso es todo lo que necesitas saber!**
