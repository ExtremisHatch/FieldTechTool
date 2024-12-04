

function Update-G3 {
    Write-Host "Updating G3 dock monitor firmware and DisplayLink afterwards."
    $dock = Resolve-Path ".\Scripts\Executables\Docks\G3_Monitor\Monitor.exe"
    $ethernet = Resolve-Path ".\Scripts\Executables\Docks\G3_Monitor\Ethernet.exe"
    $dislink = Resolve-Path ".\Scripts\Executables\Common\DisplayLink*.exe"
    
    # Dock and Ethernet firmware can be done at once
    Start-Process -FilePath $dock
    Start-Process -FilePath $ethernet -Wait
    # Waits until firmware updates complete and updates DisplayLink to work with new firmware
    Start-Process -FilePath $disLink
}