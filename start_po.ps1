# Set a unique window title
$host.ui.RawUI.WindowTitle = "HighCPULogger"

# Save the current process ID
$pid | Out-File "c:\users\choyb\Desktop\HighCPULogger.pid"

# Set CPU threshold
$cpuThreshold = 70
[int]$DurationMinutes = 10

$logFile = "c:\users\choyb\Desktop\HighCPU_Log.csv"
$endTime = (Get-Date).AddMinutes($DurationMinutes)

# Check if the log file exists
if (Test-Path $logFile) {
    # Create a timestamp for the rotated file
    $timestamp = Get-Date -Format "yyyyMMdd_HHmm"
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($logFile)
    $archivedLog = $baseName + "_$timestamp.txt"

    # Rename the existing log file
    Rename-Item -Path $logFile -NewName $archivedLog
}

# Cleanup: keep only the 2 most recent backups
$Backups = Get-ChildItem -Path "c:\users\choyb\Desktop" -Filter "$baseName_*" |
    Sort-Object LastWriteTime -Descending

if ($Backups.Count -gt 3) {
    $Backups | Select-Object -Skip 3 | Remove-Item -Force
}


# Write header if log doesn't exist
if (!(Test-Path $logFile)) {
    "Timestamp,ProcessName,ProcessID,CPU" | Out-File $logFile
}

# Monitor loop
while ((Get-Date) -lt $endTime) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $processes = Get-CimInstance Win32_PerfFormattedData_PerfProc_Process | Where-Object {
        [int]$_.PercentProcessorTime -gt $cpuThreshold -and $_.Name -ne "_Total" -and $_.Name -ne "Idle"
    }

    foreach ($proc in $processes) {
        "$timestamp,$($proc.Name),$($proc.IDProcess),$($proc.PercentProcessorTime)" | Out-File $logFile -Append
    }

    Start-Sleep -Seconds 10
}

"[$(Get-Date)] Monitoring complete." | Out-File $LogFile -Append
