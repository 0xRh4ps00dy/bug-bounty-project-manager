# Script de Backup de Base de Datos - Bug Bounty Project Manager
# Este script realiza un backup solo de la base de datos MySQL

param(
    [string]$BackupDir = "./backup/backups",
    [int]$RetentionDays = 7,
    [string]$CompressionFormat = "gzip"
)

# Configuracion de la base de datos
$DbHost = "db"
$DbUser = "root"
$DbPassword = "root_password"
$DbName = "bbpm_db"
$ContainerName = "bbpm_mysql"

# Crear directorio de backup si no existe
if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "[OK] Directorio de backup creado: $BackupDir" -ForegroundColor Green
}

# Generar nombre del archivo con timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupFileName = "${DbName}_${timestamp}.sql"
$backupFilePath = Join-Path $BackupDir $backupFileName

Write-Host "[*] Iniciando backup de la base de datos: $DbName" -ForegroundColor Cyan
Write-Host "[*] Timestamp: $timestamp" -ForegroundColor Cyan

try {
    # Ejecutar mysqldump dentro del contenedor
    Write-Host "[*] Ejecutando mysqldump..." -ForegroundColor Yellow
    $dumpOutput = docker-compose exec -T db mysqldump `
        -h $DbHost `
        -u $DbUser `
        -p"$DbPassword" `
        $DbName 2>&1

    if ($LASTEXITCODE -eq 0) {
        # Guardar el dump en archivo
        $dumpOutput | Out-File -FilePath $backupFilePath -Encoding UTF8
        
        # Obtener tamaño del archivo
        $fileSize = (Get-Item $backupFilePath).Length
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        
        Write-Host "[OK] Backup completado exitosamente" -ForegroundColor Green
        Write-Host "    Archivo: $backupFileName" -ForegroundColor Green
        Write-Host "    Tamaño: $fileSizeMB MB" -ForegroundColor Green
        Write-Host "    Ruta: $backupFilePath" -ForegroundColor Green
        
        # Comprimir el archivo
        if ($CompressionFormat -eq "gzip") {
            Write-Host "[*] Comprimiendo archivo con gzip..." -ForegroundColor Yellow
            
            try {
                # Leer el contenido del archivo
                $content = Get-Content $backupFilePath -Raw -Encoding UTF8
                $compressedPath = "$backupFilePath.gz"
                
                # Crear stream de memoria
                $memoryStream = New-Object System.IO.MemoryStream
                
                # Crear stream de compresion
                $gzipStream = New-Object System.IO.Compression.GZipStream(
                    $memoryStream, 
                    [System.IO.Compression.CompressionMode]::Compress
                )
                
                # Escribir contenido al stream de compresion
                $writer = New-Object System.IO.StreamWriter($gzipStream)
                $writer.Write($content)
                $writer.Close()
                $gzipStream.Close()
                
                # Guardar el archivo comprimido
                [System.IO.File]::WriteAllBytes($compressedPath, $memoryStream.ToArray())
                $memoryStream.Close()
                
                # Eliminar el archivo sin comprimir
                Remove-Item $backupFilePath -Force
                
                # Obtener tamaño del archivo comprimido
                $compressedSize = (Get-Item $compressedPath).Length
                $compressedSizeMB = [math]::Round($compressedSize / 1MB, 2)
                $ratio = [math]::Round(($compressedSize / $fileSize) * 100, 2)
                
                Write-Host "[OK] Archivo comprimido exitosamente" -ForegroundColor Green
                Write-Host "    Archivo: ${backupFileName}.gz" -ForegroundColor Green
                Write-Host "    Tamaño comprimido: $compressedSizeMB MB" -ForegroundColor Green
                Write-Host "    Ratio de compresion: $ratio%" -ForegroundColor Green
                
            } catch {
                Write-Host "[ERROR] Error durante la compresion: $_" -ForegroundColor Red
                exit 1
            }
        }
        
        # Limpiar backups antiguos
        Write-Host "[*] Limpiando backups antiguos (retencion: $RetentionDays dias)..." -ForegroundColor Yellow
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $oldBackups = Get-ChildItem $BackupDir -Filter "*.sql.gz" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        if ($oldBackups) {
            foreach ($oldBackup in $oldBackups) {
                Remove-Item $oldBackup.FullName -Force
                Write-Host "    [OK] Eliminado: $($oldBackup.Name)" -ForegroundColor Gray
            }
            Write-Host "[OK] Backups antiguos eliminados" -ForegroundColor Green
        } else {
            Write-Host "[i] No hay backups antiguos para eliminar" -ForegroundColor Gray
        }
        
        Write-Host "[OK] Proceso de backup completado exitosamente" -ForegroundColor Green
        exit 0
        
    } else {
        Write-Host "[ERROR] Error durante el backup de la base de datos" -ForegroundColor Red
        Write-Host "    Salida: $dumpOutput" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "[ERROR] Error general ejecutando backup: $_" -ForegroundColor Red
    exit 1
}
