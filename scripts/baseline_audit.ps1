<#
.SYNOPSIS
    ARCX95 Baseline Audit Script - Ground Zero System DNA Capture
    
.DESCRIPTION
    Comprehensive system audit for the ARCX95 Action Data Automation Plan.
    Captures hardware, software, drivers, and network configuration to establish
    the "Ground Zero" baseline for the Sovereign Nexus Core.
    
.NOTES
    Author: Network 95 Collaboration
    Version: 1.0
    Date: January 10, 2026
    Location: Leland, Iowa
    
.OUTPUTS
    JSON report saved to: $env:USERPROFILE\ARCX95\Reports\baseline_report.json
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = "$env:USERPROFILE\ARCX95\Reports"
)

# Initialize
$ErrorActionPreference = 'Continue'
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = Join-Path $OutputPath "baseline_report_$timestamp.json"

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "🚀 ARCX95 BASELINE AUDIT INITIATED" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Audit Object
$audit = @{
    Timestamp = Get-Date -Format "o"
    Location = "Leland, Iowa, US"
    Phase = "Ground Zero Synchronization"
    SystemDNA = @{}
    Hardware = @{}
    Drivers = @{}
    Software = @{}
    Network = @{}
    Storage = @{}
    Performance = @{}
}

# 1. System DNA
Write-Host "[1/7] Capturing System DNA..." -ForegroundColor Yellow
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$bios = Get-CimInstance Win32_BIOS

$audit.SystemDNA = @{
    Hostname = $cs.Name
    Manufacturer = $cs.Manufacturer
    Model = $cs.Model
    TotalPhysicalMemory_GB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    OS = $os.Caption
    OSVersion = $os.Version
    OSArchitecture = $os.OSArchitecture
    BIOSVersion = $bios.SMBIOSBIOSVersion
    SerialNumber = $bios.SerialNumber
}
Write-Host "✓ System DNA captured" -ForegroundColor Green

# 2. Hardware Inventory
Write-Host "[2/7] Scanning Hardware Components..." -ForegroundColor Yellow
$cpu = Get-CimInstance Win32_Processor
$gpu = Get-CimInstance Win32_VideoController
$disks = Get-CimInstance Win32_DiskDrive

$audit.Hardware = @{
    CPU = @{
        Name = $cpu.Name
        Cores = $cpu.NumberOfCores
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        MaxClockSpeed_GHz = [math]::Round($cpu.MaxClockSpeed / 1000, 2)
    }
    GPU = @($gpu | ForEach-Object {
        @{
            Name = $_.Name
            DriverVersion = $_.DriverVersion
            VideoRAM_GB = [math]::Round($_.AdapterRAM / 1GB, 2)
        }
    })
    Disks = @($disks | ForEach-Object {
        @{
            Model = $_.Model
            Size_GB = [math]::Round($_.Size / 1GB, 2)
            Interface = $_.InterfaceType
        }
    })
}
Write-Host "✓ Hardware inventory complete" -ForegroundColor Green

# 3. Driver Status
Write-Host "[3/7] Analyzing Driver Status..." -ForegroundColor Yellow
$drivers = Get-CimInstance Win32_PnPSignedDriver | 
    Where-Object { $_.DriverProviderName -like "*MSI*" -or $_.DriverProviderName -like "*NVIDIA*" -or $_.DriverProviderName -like "*Intel*" -or $_.DriverProviderName -like "*AMD*" } |
    Select-Object DeviceName, DriverVersion, DriverDate, DriverProviderName

$audit.Drivers = @{
    Count = $drivers.Count
    KeyDrivers = @($drivers | ForEach-Object {
        @{
            Device = $_.DeviceName
            Version = $_.DriverVersion
            Date = $_.DriverDate
            Provider = $_.DriverProviderName
        }
    })
    MSICenterDetected = Test-Path "C:\Program Files (x86)\MSI\One Dragon Center\MSI_SDK.exe"
}
Write-Host "✓ Driver analysis complete" -ForegroundColor Green

# 4. Software Ecosystem
Write-Host "[4/7] Cataloging Software Ecosystem..." -ForegroundColor Yellow
$powershellVersion = $PSVersionTable.PSVersion.ToString()
$pythonInstalled = $null -ne (Get-Command python -ErrorAction SilentlyContinue)
$pythonVersion = if ($pythonInstalled) { (python --version 2>&1) } else { "Not Installed" }
$gitInstalled = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
$gitVersion = if ($gitInstalled) { (git --version) } else { "Not Installed" }

$audit.Software = @{
    PowerShell = $powershellVersion
    Python = $pythonVersion
    Git = $gitVersion
    OllamaInstalled = Test-Path "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    VSCodeInstalled = Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
}
Write-Host "✓ Software catalog complete" -ForegroundColor Green

# 5. Network Configuration
Write-Host "[5/7] Mapping Network Configuration..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
$ipconfig = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -notlike '127.*' }

$audit.Network = @{
    ActiveAdapters = @($adapters | ForEach-Object {
        @{
            Name = $_.Name
            Status = $_.Status
            LinkSpeed = $_.LinkSpeed
            MacAddress = $_.MacAddress
        }
    })
    IPv4Addresses = @($ipconfig | ForEach-Object { $_.IPAddress })
    InternetConnected = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
}
Write-Host "✓ Network mapping complete" -ForegroundColor Green

# 6. Storage Analysis
Write-Host "[6/7] Analyzing Storage Capacity..." -ForegroundColor Yellow
$volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }

$audit.Storage = @{
    Volumes = @($volumes | ForEach-Object {
        @{
            DriveLetter = $_.DriveLetter
            FileSystem = $_.FileSystem
            Size_GB = [math]::Round($_.Size / 1GB, 2)
            FreeSpace_GB = [math]::Round($_.SizeRemaining / 1GB, 2)
            PercentFree = [math]::Round(($_.SizeRemaining / $_.Size) * 100, 1)
        }
    })
}
Write-Host "✓ Storage analysis complete" -ForegroundColor Green

# 7. Performance Metrics
Write-Host "[7/7] Capturing Performance Metrics..." -ForegroundColor Yellow
$cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
$memory = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime

$audit.Performance = @{
    CPULoad_Percent = $cpuLoad
    MemoryUsed_GB = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
    MemoryFree_GB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    MemoryUsage_Percent = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 1)
    Uptime_Hours = [math]::Round($uptime.TotalHours, 2)
}
Write-Host "✓ Performance metrics captured" -ForegroundColor Green

# Generate Report
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "GENERATING GROUND ZERO REPORT..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$audit | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "✓ BASELINE AUDIT COMPLETE" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Report Location: $reportPath" -ForegroundColor White
Write-Host "📈 System Status: READY FOR OBELISK DEPLOYMENT" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review baseline report" -ForegroundColor White
Write-Host "  2. Initialize Memory Palace (SQLite + ChromaDB)" -ForegroundColor White
Write-Host "  3. Deploy Multi-Lens Layer" -ForegroundColor White
Write-Host "  4. Activate Obelisk Framework" -ForegroundColor White
Write-Host ""
Write-Host "ARCX95 | Network 95 Collaboration | Leland, Iowa" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
