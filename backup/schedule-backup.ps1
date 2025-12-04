# Script para Programar Backups Automáticos en Windows Task Scheduler
# Configura una tarea programada para ejecutar backups automáticamente

param(
    [ValidateSet("Daily", "Hourly", "Weekly")]
    [string]$Frequency = "Daily",
    [string]$Time = "02:00"
)

# Configuración
$ScriptPath = "C:\Users\marcosjurado\Dockers\bug-bounty-project-manager\backup\backup.ps1"
$TaskName = "BBPM_AutoBackup"
$TaskDescription = "Backup automático de Bug Bounty Project Manager"

# Colores para output
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

Write-Info "=== Configurador de Backups Automáticos ==="
Write-Info "Script: $ScriptPath"
Write-Info "Frecuencia: $Frequency"
Write-Info "Hora: $Time"

# Verificar que el script de backup existe
if (!(Test-Path $ScriptPath)) {
    Write-Error "✗ No se encontró el script de backup en: $ScriptPath"
    exit 1
}

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "✗ Este script requiere permisos de administrador"
    Write-Info "  Ejecuta PowerShell como Administrador e intenta de nuevo"
    exit 1
}

# Eliminar tarea existente si existe
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Info "Eliminando tarea programada existente..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Success "✓ Tarea anterior eliminada"
}

# Crear acción para ejecutar el script
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

# Configurar disparador según frecuencia
switch ($Frequency) {
    "Hourly" {
        $Trigger = New-ScheduledTaskTrigger -Once -At "00:00" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration ([TimeSpan]::MaxValue)
        Write-Info "Configurando backup cada hora"
    }
    "Daily" {
        $Trigger = New-ScheduledTaskTrigger -Daily -At $Time
        Write-Info "Configurando backup diario a las $Time"
    }
    "Weekly" {
        $Trigger = New-ScheduledTaskTrigger -Weekly -At $Time -DaysOfWeek Sunday
        Write-Info "Configurando backup semanal los domingos a las $Time"
    }
}

# Configurar opciones de la tarea
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

# Obtener usuario actual
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest

# Registrar la tarea
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Description $TaskDescription `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -Principal $Principal `
        -Force | Out-Null
    
    Write-Success "`n✓ Tarea programada creada exitosamente"
    Write-Info "  Nombre: $TaskName"
    Write-Info "  Frecuencia: $Frequency"
    
    # Mostrar información de la tarea
    Write-Info "`n=== Información de la Tarea ==="
    Get-ScheduledTask -TaskName $TaskName | Format-List TaskName, State, @{Name="NextRun";Expression={(Get-ScheduledTaskInfo $_).NextRunTime}}
    
    Write-Info "`n=== Comandos Útiles ==="
    Write-Host "  Ver estado: " -NoNewline; Write-Host "Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Yellow
    Write-Host "  Ejecutar ahora: " -NoNewline; Write-Host "Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Yellow
    Write-Host "  Deshabilitar: " -NoNewline; Write-Host "Disable-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Yellow
    Write-Host "  Eliminar: " -NoNewline; Write-Host "Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor Yellow
    
    Write-Info "`nPuedes ver y gestionar la tarea en el Programador de Tareas de Windows"
    
} catch {
    Write-Error "✗ Error al crear tarea programada: $_"
    exit 1
}
