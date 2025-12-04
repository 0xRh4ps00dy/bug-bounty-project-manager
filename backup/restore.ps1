# Script de Restauración para Bug Bounty Project Manager
# Restaura backups de la base de datos y archivos del proyecto

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupFile,
    [switch]$DatabaseOnly,
    [switch]$FilesOnly
)

# Configuración
$ProjectDir = "C:\Users\marcosjurado\Dockers\bug-bounty-project-manager"
$BackupDir = Join-Path $ProjectDir "backup\backups"
$TempRestoreDir = Join-Path $ProjectDir "backup\temp_restore"

# Colores para output
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

# Si no se especificó archivo, mostrar lista de backups disponibles
if (-not $BackupFile) {
    Write-Info "=== Backups Disponibles ==="
    $Backups = Get-ChildItem -Path $BackupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending
    
    if ($Backups.Count -eq 0) {
        Write-Error "No se encontraron backups en: $BackupDir"
        exit 1
    }
    
    for ($i = 0; $i -lt $Backups.Count; $i++) {
        $backup = $Backups[$i]
        $size = [math]::Round($backup.Length / 1MB, 2)
        $date = $backup.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "$($i + 1). $($backup.Name) - $size MB - $date"
    }
    
    $selection = Read-Host "`nSelecciona el número del backup a restaurar (o 'q' para salir)"
    
    if ($selection -eq 'q') {
        Write-Info "Operación cancelada"
        exit 0
    }
    
    try {
        $index = [int]$selection - 1
        $BackupFile = $Backups[$index].FullName
        Write-Success "Seleccionado: $($Backups[$index].Name)"
    } catch {
        Write-Error "Selección inválida"
        exit 1
    }
}

# Verificar que el archivo existe
if (!(Test-Path $BackupFile)) {
    Write-Error "El archivo de backup no existe: $BackupFile"
    exit 1
}

# Confirmar restauración
Write-Warning "`n⚠️  ADVERTENCIA: Esta operación sobrescribirá los datos actuales"
$confirm = Read-Host "¿Estás seguro de continuar? (si/no)"
if ($confirm -ne 'si') {
    Write-Info "Operación cancelada"
    exit 0
}

# Verificar que Docker esté corriendo
Write-Info "`nVerificando estado de Docker..."
try {
    docker ps | Out-Null
    Write-Success "✓ Docker está corriendo"
} catch {
    Write-Error "✗ Docker no está disponible. Inicia Docker Desktop."
    exit 1
}

# Extraer backup
Write-Info "`n=== Extrayendo Backup ==="
try {
    if (Test-Path $TempRestoreDir) {
        Remove-Item -Path $TempRestoreDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempRestoreDir -Force | Out-Null
    
    Expand-Archive -Path $BackupFile -DestinationPath $TempRestoreDir -Force
    Write-Success "✓ Backup extraído"
    
    # Buscar la carpeta del backup dentro del directorio temporal
    $ExtractedFolder = Get-ChildItem -Path $TempRestoreDir -Directory | Select-Object -First 1
    $RestorePath = $ExtractedFolder.FullName
} catch {
    Write-Error "✗ Error al extraer backup: $_"
    exit 1
}

# Restaurar Base de Datos
if (-not $FilesOnly) {
    Write-Info "`n=== Restaurando Base de Datos ==="
    try {
        $SQLFile = Get-ChildItem -Path $RestorePath -Filter "*.sql" | Select-Object -First 1
        
        if ($SQLFile) {
            Write-Info "Importando base de datos..."
            
            # Copiar archivo SQL al contenedor
            docker cp $SQLFile.FullName bbpm_mysql:/tmp/restore.sql
            
            # Ejecutar restauración
            docker exec bbpm_mysql mysql -u root -proot_password -e "DROP DATABASE IF EXISTS bbpm_db; CREATE DATABASE bbpm_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
            docker exec bbpm_mysql mysql -u root -proot_password bbpm_db -e "source /tmp/restore.sql"
            
            # Limpiar archivo temporal
            docker exec bbpm_mysql rm /tmp/restore.sql
            
            Write-Success "✓ Base de datos restaurada"
        } else {
            Write-Warning "⚠ No se encontró archivo SQL en el backup"
        }
    } catch {
        Write-Error "✗ Error al restaurar base de datos: $_"
    }
}

# Restaurar Archivos
if (-not $DatabaseOnly) {
    Write-Info "`n=== Restaurando Archivos ==="
    try {
        $FilesPath = Join-Path $RestorePath "files"
        
        if (Test-Path $FilesPath) {
            # Lista de carpetas a restaurar
            $FoldersToRestore = @("www", "public", "app", "config", "routes", "mysql")
            
            foreach ($folder in $FoldersToRestore) {
                $sourcePath = Join-Path $FilesPath $folder
                $destPath = Join-Path $ProjectDir $folder
                
                if (Test-Path $sourcePath) {
                    # Crear backup de carpeta actual antes de sobrescribir
                    if (Test-Path $destPath) {
                        $backupCurrentPath = "$destPath.backup_" + (Get-Date -Format "yyyyMMdd_HHmmss")
                        Copy-Item -Path $destPath -Destination $backupCurrentPath -Recurse -Force
                        Write-Info "  Backup actual guardado: $folder.backup_*"
                    }
                    
                    # Restaurar carpeta
                    Remove-Item -Path $destPath -Recurse -Force -ErrorAction SilentlyContinue
                    Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
                    Write-Success "  ✓ $folder restaurado"
                }
            }
            
            # Restaurar archivos de la raíz
            $RootFiles = @("docker-compose.yml", "composer.json", "composer.lock", ".gitignore")
            foreach ($file in $RootFiles) {
                $sourceFile = Join-Path $FilesPath $file
                if (Test-Path $sourceFile) {
                    Copy-Item -Path $sourceFile -Destination $ProjectDir -Force
                    Write-Success "  ✓ $file restaurado"
                }
            }
            
            Write-Success "✓ Archivos restaurados"
        } else {
            Write-Warning "⚠ No se encontró carpeta 'files' en el backup"
        }
    } catch {
        Write-Error "✗ Error al restaurar archivos: $_"
    }
}

# Limpiar directorio temporal
Write-Info "`n=== Limpieza ==="
try {
    Remove-Item -Path $TempRestoreDir -Recurse -Force
    Write-Success "✓ Archivos temporales eliminados"
} catch {
    Write-Warning "⚠ No se pudieron eliminar archivos temporales"
}

# Reiniciar contenedores
Write-Info "`n=== Reiniciando Contenedores ==="
try {
    Set-Location $ProjectDir
    docker-compose restart
    Write-Success "✓ Contenedores reiniciados"
} catch {
    Write-Warning "⚠ Error al reiniciar contenedores. Reinícialos manualmente con: docker-compose restart"
}

Write-Info "`n=== Restauración Completada ==="
Write-Success "✓ El sistema ha sido restaurado desde el backup"
Write-Info "  Accede a la aplicación: http://localhost"
Write-Info "  Accede a phpMyAdmin: http://localhost:8080"
