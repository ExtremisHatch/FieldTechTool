
function Get-SystemInfo {
    # Get machine name and current OS. 
    $machine_name = $env:COMPUTERNAME
    $machine_os_version = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Version
    
    # Printing out the machine name and OS version.
    Write-Host "Machine Name: $machine_name"
    Write-Host "OS Version: $machine_os_version"

}

function Get-GraphicsInfo {
    # Get all Graphics card info. Integrated and dedicated.
    $videoControllers = Get-CimInstance -ClassName Win32_VideoController

    # Printing out the graphics card info.
    foreach ($vc in $videoControllers){
        Write-Host "Graphics Card: $($vc.Name)"
        Write-Host "Description: $($vc.Description)"
        Write-Host "Driver Version: $($vc.DriverVersion)"
        Write-Host "Video Driver Date: $($vc.DriverDate)"
        Write-Host "Video Processor: $($vc.VideoProcessor)"
        Write-Host "Video Memory: $($vc.AdapterRAM) bytes"
        Write-Host "Video Architecture: $($vc.VideoArchitecture)"
        Write-Host "Video Memory Type: $($vc.VideoMemoryType)"
        Write-Host "Video Mode Description: $($vc.VideoModeDescription)"
        Write-Host "---------------------------"
    }
    
}

function Get-NetworkInfo {
    # Get IP address info such as IPv4, IPv6 (if available), and default gateway
    # This part may be tricky because of the virtualized ethernet ports and interfaces on each machine.
    # May have to get a general ipconfig output and cut out info that isn't needed. 
    $ipconfig = ipconfig /all
    $lastInterface = $null
    Write-Host "Network Interface Details"
    $ipconfig -split "`r`n" | ForEach-Object {
        if ($_ -match "^(.*):$") {
            $lastInterface = $matches[1]
        } elseif ($_ -match "(IPv4 Address|IPv6 Address|Default Gateway)") {
            Write-Host "$lastInterface - $_"
        }
    }
    Write-Host "---------------------------"
    
}

function Get-SystemSummary {
    # Function to summarize all of the above information.
    # Need to come up with a method to optionally save this information 
    Get-SystemInfo
    Get-GraphicsInfo
    Get-NetworkInfo  
} 

