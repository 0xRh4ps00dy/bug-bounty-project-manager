#!/usr/bin/env pwsh
# BBPM Backup Manager - Sistema Simplificado de Copias de Seguridad
# Uso: .\bbpm-backup.ps1 [comando]

param(
    [Parameter(Position=0)]
    [string]$Command = "menu"
)

$ProjectDir = Split-Path -Parent $PSScriptRoot
$BackupDir = "$PSScriptRoot\backups"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Colores
function Write-Title { param($msg) Write-Host "`n$msg" -ForegroundColor Cyan -BackgroundColor DarkBlue }
function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "→ $msg" -ForegroundColor Cyan }
function Write-Warn { param($msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       🔒 BBPM BACKUP MANAGER - Sistema Simplificado      ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Docker {
    try {
        docker ps | Out-Null
        return $true
    } catch {
        Write-Err "Docker no está corriendo. Inicia Docker Desktop."
        return $false
    }
}

function Create-Backup {
    Show-Banner
    Write-Title " CREAR BACKUP "
    
    if (!(Test-Docker)) { return }
    
    Write-Info "Iniciando proceso de backup..."
    $BackupName = "bbpm_backup_$Timestamp"
    $BackupPath = "$BackupDir\$BackupName"
    
    # Crear directorio
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    
    # 1. Backup Base de Datos
    Write-Info "Exportando base de datos..."
    $DBFile = "$BackupPath\database.sql"
    docker exec bbpm_mysql mysqldump -u root -proot_password --databases bbpm_db --routines --triggers --events 2>$null | Out-File -FilePath $DBFile -Encoding utf8
    
    if (Test-Path $DBFile) {
        $size = [math]::Round((Get-Item $DBFile).Length / 1KB, 2)
        Write-Success "Base de datos exportada ($size KB)"
    } else {
        Write-Err "Error al exportar base de datos"
        Remove-Item $BackupPath -Recurse -Force
        return
    }
    
    # 2. Backup Archivos
    Write-Info "Copiando archivos del proyecto..."
    $FilesPath = "$BackupPath\files"
    New-Item -ItemType Directory -Path $FilesPath -Force | Out-Null
    
    @("www", "public", "app", "config", "routes", "mysql") | ForEach-Object {
        if (Test-Path "$ProjectDir\$_") {
            Copy-Item "$ProjectDir\$_" -Destination $FilesPath -Recurse -Force
        }
    }
    
    @("docker-compose.yml", "composer.json") | ForEach-Object {
        if (Test-Path "$ProjectDir\$_") {
            Copy-Item "$ProjectDir\$_" -Destination $FilesPath -Force
        }
    }
    Write-Success "Archivos copiados"
    
    # 3. Comprimir
    Write-Info "Comprimiendo backup..."
    $ZipFile = "$BackupPath.zip"
    Compress-Archive -Path $BackupPath -DestinationPath $ZipFile -Force
    Remove-Item $BackupPath -Recurse -Force
    
    $zipSize = [math]::Round((Get-Item $ZipFile).Length / 1MB, 2)
    Write-Success "Backup creado: $zipSize MB"
    Write-Info "Ubicación: $ZipFile"
    
    # Limpiar backups antiguos (>7 días)
    $old = Get-ChildItem $BackupDir -Filter "*.zip" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
    if ($old.Count -gt 0) {
        $old | Remove-Item -Force
        Write-Info "Eliminados $($old.Count) backup(s) antiguo(s)"
    }
    
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
}

function Restore-Backup {
    Show-Banner
    Write-Title " RESTAURAR BACKUP "
    
    if (!(Test-Docker)) { return }
    
    $backups = Get-ChildItem $BackupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Warn "No hay backups disponibles"
        Write-Host ""
        Read-Host "Presiona Enter para continuar"
        return
    }
    
    Write-Host "Backups disponibles:" -ForegroundColor Yellow
    Write-Host ""
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $b = $backups[$i]
        $size = [math]::Round($b.Length / 1MB, 2)
        $date = $b.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "  $($i+1). $($b.Name)" -ForegroundColor White
        Write-Host "     $date - $size MB" -ForegroundColor Gray
    }
    
    Write-Host ""
    $selection = Read-Host "Selecciona número (o Enter para cancelar)"
    
    if ([string]::IsNullOrWhiteSpace($selection)) {
        Write-Info "Operación cancelada"
        Start-Sleep 1
        return
    }
    
    try {
        $index = [int]$selection - 1
        $BackupFile = $backups[$index].FullName
    } catch {
        Write-Err "Selección inválida"
        Start-Sleep 2
        return
    }
    
    Write-Host ""
    Write-Warn "⚠ ADVERTENCIA: Esto sobrescribirá los datos actuales"
    $confirm = Read-Host "¿Continuar? (escribe SI en mayúsculas)"
    
    if ($confirm -ne "SI") {
        Write-Info "Operación cancelada"
        Start-Sleep 1
        return
    }
    
    Write-Host ""
    Write-Info "Restaurando backup..."
    
    # Extraer
    $TempDir = "$PSScriptRoot\temp_restore"
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path $BackupFile -DestinationPath $TempDir -Force
    
    $RestorePath = Get-ChildItem $TempDir -Directory | Select-Object -First 1 -ExpandProperty FullName
    
    # Restaurar BD
    Write-Info "Restaurando base de datos..."
    $SQLFile = Get-ChildItem "$RestorePath\*.sql" | Select-Object -First 1
    if ($SQLFile) {
        docker cp $SQLFile.FullName bbpm_mysql:/tmp/restore.sql
        docker exec bbpm_mysql mysql -u root -proot_password -e "DROP DATABASE IF EXISTS bbpm_db; CREATE DATABASE bbpm_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>$null
        docker exec bbpm_mysql mysql -u root -proot_password bbpm_db -e "source /tmp/restore.sql" 2>$null
        docker exec bbpm_mysql rm /tmp/restore.sql
        Write-Success "Base de datos restaurada"
    }
    
    # Restaurar archivos
    Write-Info "Restaurando archivos..."
    $FilesPath = "$RestorePath\files"
    if (Test-Path $FilesPath) {
        @("www", "public", "app", "config", "routes", "mysql") | ForEach-Object {
            $src = "$FilesPath\$_"
            $dst = "$ProjectDir\$_"
            if (Test-Path $src) {
                Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
                Copy-Item $src -Destination $dst -Recurse -Force
            }
        }
        Write-Success "Archivos restaurados"
    }
    
    # Limpiar
    Remove-Item $TempDir -Recurse -Force
    
    # Reiniciar contenedores
    Write-Info "Reiniciando contenedores..."
    Set-Location $ProjectDir
    docker-compose restart 2>$null | Out-Null
    
    Write-Success "¡Restauración completada!"
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
}

function Show-Backups {
    Show-Banner
    Write-Title " BACKUPS DISPONIBLES "
    
    $backups = Get-ChildItem $BackupDir -Filter "*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Warn "No hay backups disponibles"
    } else {
        $totalSize = ($backups | Measure-Object -Property Length -Sum).Sum / 1MB
        
        Write-Host ""
        Write-Host "Total: $($backups.Count) backup(s) - $([math]::Round($totalSize, 2)) MB" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($b in $backups) {
            $size = [math]::Round($b.Length / 1MB, 2)
            $date = $b.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            $age = [math]::Round(((Get-Date) - $b.LastWriteTime).TotalDays, 1)
            
            Write-Host "  📦 $($b.Name)" -ForegroundColor Cyan
            Write-Host "     $date - $size MB - $age días" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
}

function Setup-Auto {
    Show-Banner
    Write-Title " CONFIGURAR BACKUPS AUTOMÁTICOS "
    
    Write-Host ""
    Write-Host "Opciones de programación:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Diario a las 2:00 AM" -ForegroundColor White
    Write-Host "  2. Cada 12 horas" -ForegroundColor White
    Write-Host "  3. Cada 6 horas" -ForegroundColor White
    Write-Host "  4. Semanal (Domingos 2:00 AM)" -ForegroundColor White
    Write-Host "  5. Desactivar backups automáticos" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Selecciona opción (o Enter para cancelar)"
    
    if ([string]::IsNullOrWhiteSpace($choice)) {
        Write-Info "Operación cancelada"
        Start-Sleep 1
        return
    }
    
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Err "Se requieren permisos de administrador"
        Write-Info "Ejecuta PowerShell como Administrador"
        Write-Host ""
        Read-Host "Presiona Enter para continuar"
        return
    }
    
    $TaskName = "BBPM_AutoBackup"
    $ScriptPath = "$PSScriptRoot\bbpm-backup.ps1"
    
    # Eliminar tarea existente
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    
    if ($choice -eq "5") {
        Write-Success "Backups automáticos desactivados"
        Start-Sleep 2
        return
    }
    
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`" backup"
    
    switch ($choice) {
        "1" { 
            $Trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
            $desc = "Diario a las 2:00 AM"
        }
        "2" { 
            $Trigger = New-ScheduledTaskTrigger -Once -At "00:00" -RepetitionInterval (New-TimeSpan -Hours 12) -RepetitionDuration ([TimeSpan]::MaxValue)
            $desc = "Cada 12 horas"
        }
        "3" { 
            $Trigger = New-ScheduledTaskTrigger -Once -At "00:00" -RepetitionInterval (New-TimeSpan -Hours 6) -RepetitionDuration ([TimeSpan]::MaxValue)
            $desc = "Cada 6 horas"
        }
        "4" { 
            $Trigger = New-ScheduledTaskTrigger -Weekly -At "02:00" -DaysOfWeek Sunday
            $desc = "Semanal (Domingos 2:00 AM)"
        }
        default {
            Write-Err "Opción inválida"
            Start-Sleep 2
            return
        }
    }
    
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force | Out-Null
    
    Write-Host ""
    Write-Success "¡Backups automáticos configurados!"
    Write-Info "Frecuencia: $desc"
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
}

function Show-Menu {
    while ($true) {
        Show-Banner
        
        Write-Host "  1. 💾 Crear Backup" -ForegroundColor Green
        Write-Host "  2. ♻️  Restaurar Backup" -ForegroundColor Yellow
        Write-Host "  3. 📋 Ver Backups" -ForegroundColor Cyan
        Write-Host "  4. ⏰ Configurar Automático" -ForegroundColor Magenta
        Write-Host "  5. ❌ Salir" -ForegroundColor Red
        Write-Host ""
        
        $choice = Read-Host "Selecciona una opción"
        
        switch ($choice) {
            "1" { Create-Backup }
            "2" { Restore-Backup }
            "3" { Show-Backups }
            "4" { Setup-Auto }
            "5" { 
                Write-Host ""
                Write-Info "¡Hasta luego!"
                exit 0
            }
            default {
                Write-Warn "Opción inválida"
                Start-Sleep 1
            }
        }
    }
}

# Punto de entrada
switch ($Command.ToLower()) {
    "backup" { 
        Create-Backup
        exit 0
    }
    "restore" { 
        Restore-Backup
        exit 0
    }
    "list" { 
        Show-Backups
        exit 0
    }
    "auto" { 
        Setup-Auto
        exit 0
    }
    default { 
        Show-Menu
    }
}
