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
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($logFile)
    $archivedLog = $baseName + "_$timestamp.txt"

    # Rename the existing log file
    Rename-Item -Path $logFile -NewName $archivedLog
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
