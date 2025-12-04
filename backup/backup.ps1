# Script de Backup para Bug Bounty Project Manager
# Crea copias de seguridad de la base de datos MySQL y archivos del proyecto

param(
    [string]$BackupDir = "C:\Users\marcosjurado\Dockers\bug-bounty-project-manager\backup\backups",
    [int]$RetentionDays = 7
)

# Configuración
$ProjectDir = "C:\Users\marcosjurado\Dockers\bug-bounty-project-manager"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupName = "bbpm_backup_$Timestamp"
$BackupPath = Join-Path $BackupDir $BackupName

# Colores para output
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

# Verificar que Docker esté corriendo
Write-Info "Verificando estado de Docker..."
try {
    docker ps | Out-Null
    Write-Success "✓ Docker está corriendo"
} catch {
    Write-Error "✗ Docker no está disponible. Inicia Docker Desktop."
    exit 1
}

# Crear directorio de backup
Write-Info "Creando directorio de backup..."
if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
Write-Success "✓ Directorio creado: $BackupPath"

# 1. Backup de la Base de Datos MySQL
Write-Info "`n=== Backup de Base de Datos ==="
$DBBackupFile = Join-Path $BackupPath "database_$Timestamp.sql"
$DockerCommand = "docker exec bbpm_mysql mysqldump -u root -proot_password --databases bbpm_db --routines --triggers --events > `"$DBBackupFile`""

try {
    Write-Info "Exportando base de datos..."
    docker exec bbpm_mysql mysqldump -u root -proot_password --databases bbpm_db --routines --triggers --events | Out-File -FilePath $DBBackupFile -Encoding utf8
    
    if (Test-Path $DBBackupFile) {
        $DBSize = (Get-Item $DBBackupFile).Length / 1KB
        Write-Success "✓ Base de datos exportada: $([math]::Round($DBSize, 2)) KB"
    }
} catch {
    Write-Error "✗ Error al exportar base de datos: $_"
}

# 2. Backup de Archivos del Proyecto
Write-Info "`n=== Backup de Archivos del Proyecto ==="
$FilesBackupPath = Join-Path $BackupPath "files"

$FoldersToBackup = @(
    "www",
    "public",
    "app",
    "config",
    "routes",
    "mysql"
)

try {
    Write-Info "Copiando archivos del proyecto..."
    foreach ($folder in $FoldersToBackup) {
        $sourcePath = Join-Path $ProjectDir $folder
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $FilesBackupPath $folder
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
            Write-Success "  ✓ $folder copiado"
        }
    }
    
    # Copiar archivos importantes de la raíz
    $RootFiles = @("docker-compose.yml", "composer.json", "composer.lock", ".gitignore", "README.md")
    foreach ($file in $RootFiles) {
        $sourceFile = Join-Path $ProjectDir $file
        if (Test-Path $sourceFile) {
            Copy-Item -Path $sourceFile -Destination $FilesBackupPath -Force
            Write-Success "  ✓ $file copiado"
        }
    }
} catch {
    Write-Error "✗ Error al copiar archivos: $_"
}

# 3. Crear archivo comprimido
Write-Info "`n=== Comprimiendo Backup ==="
$ZipFile = "$BackupPath.zip"
try {
    Compress-Archive -Path $BackupPath -DestinationPath $ZipFile -Force
    $ZipSize = (Get-Item $ZipFile).Length / 1MB
    Write-Success "✓ Backup comprimido: $([math]::Round($ZipSize, 2)) MB"
    
    # Eliminar carpeta temporal
    Remove-Item -Path $BackupPath -Recurse -Force
    Write-Info "  Carpeta temporal eliminada"
} catch {
    Write-Error "✗ Error al comprimir: $_"
}

# 4. Limpiar backups antiguos
Write-Info "`n=== Limpieza de Backups Antiguos ==="
try {
    $OldBackups = Get-ChildItem -Path $BackupDir -Filter "*.zip" | 
                  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }
    
    if ($OldBackups.Count -gt 0) {
        Write-Info "Eliminando backups con más de $RetentionDays días..."
        foreach ($backup in $OldBackups) {
            Remove-Item $backup.FullName -Force
            Write-Warning "  ✗ Eliminado: $($backup.Name)"
        }
        Write-Success "✓ $($OldBackups.Count) backup(s) antiguo(s) eliminado(s)"
    } else {
        Write-Info "No hay backups antiguos para eliminar"
    }
} catch {
    Write-Error "✗ Error en limpieza: $_"
}

# 5. Resumen Final
Write-Info "`n=== Resumen del Backup ==="
$AllBackups = Get-ChildItem -Path $BackupDir -Filter "*.zip"
$TotalSize = ($AllBackups | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Success "✓ Backup completado exitosamente"
Write-Info "  Ubicación: $ZipFile"
Write-Info "  Total de backups: $($AllBackups.Count)"
Write-Info "  Espacio total usado: $([math]::Round($TotalSize, 2)) MB"
Write-Info "  Retención configurada: $RetentionDays días"
