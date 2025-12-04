# Script de Restauración de Base de Datos - Bug Bounty Project Manager
# Este script restaura un backup de la base de datos MySQL

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    
    [string]$DbHost = "db",
    [string]$DbUser = "root",
    [string]$DbPassword = "root_password",
    [string]$DbName = "bbpm_db",
    [switch]$Force
)

# Validar que el archivo existe
if (!(Test-Path $BackupFile)) {
    Write-Host "[✗] El archivo de backup no existe: $BackupFile" -ForegroundColor Red
    exit 1
}

$fileSize = (Get-Item $BackupFile).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)

Write-Host "[*] Preparando restauración de backup" -ForegroundColor Cyan
Write-Host "    Archivo: $(Split-Path $BackupFile -Leaf)" -ForegroundColor Cyan
Write-Host "    Tamaño: $fileSizeMB MB" -ForegroundColor Cyan
Write-Host "    Base de datos: $DbName" -ForegroundColor Cyan

# Confirmar si es necesario
if (!$Force) {
    $response = Read-Host "`n[!] ¿Deseas continuar con la restauración? (Esto sobrescribirá los datos actuales) [s/N]"
    if ($response -ne "s" -and $response -ne "S") {
        Write-Host "[✗] Restauración cancelada" -ForegroundColor Yellow
        exit 0
    }
}

# Descomprimir si es necesario
$sqlFile = $BackupFile
if ($BackupFile -like "*.gz") {
    Write-Host "[*] Descomprimiendo archivo..." -ForegroundColor Yellow
    
    $sqlFile = $BackupFile -replace "\.gz$", ""
    
    if (Test-Path $sqlFile) {
        Remove-Item $sqlFile -Force
    }
    
    # Descomprimir
    $gzipStream = New-Object System.IO.FileStream($BackupFile, [System.IO.FileMode]::Open)
    $memoryStream = New-Object System.IO.MemoryStream
    $decompressor = New-Object System.IO.Compression.GZipStream($gzipStream, [System.IO.Compression.CompressionMode]::Decompress)
    $decompressor.CopyTo($memoryStream)
    $decompressor.Close()
    $gzipStream.Close()
    
    [System.IO.File]::WriteAllBytes($sqlFile, $memoryStream.ToArray())
    $memoryStream.Close()
    
    Write-Host "[✓] Archivo descomprimido" -ForegroundColor Green
}

try {
    Write-Host "[*] Restaurando base de datos..." -ForegroundColor Yellow
    
    # Leer el contenido del archivo SQL
    $sqlContent = Get-Content $sqlFile -Raw -Encoding UTF8
    
    # Ejecutar la restauración
    $sqlContent | docker-compose exec -T db mysql `
        -h $DbHost `
        -u $DbUser `
        -p"$DbPassword" `
        $DbName 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[✓] Restauración completada exitosamente" -ForegroundColor Green
        Write-Host "    Base de datos: $DbName" -ForegroundColor Green
        Write-Host "    Datos restaurados desde: $(Split-Path $BackupFile -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "[✗] Error durante la restauración" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "[✗] Error restaurando base de datos: $_" -ForegroundColor Red
    exit 1
} finally {
    # Limpiar archivo temporal descomprimido
    if ($BackupFile -like "*.gz" -and (Test-Path $sqlFile)) {
        Remove-Item $sqlFile -Force
    }
}

Write-Host "[✓] Proceso de restauración completado" -ForegroundColor Green
