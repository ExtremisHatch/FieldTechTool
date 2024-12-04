

function Update-G4 {
    Write-Host 'Updating G4 dock firmware and DisplayLink afterwards.'
    $dock = Resolve-Path ".\Scripts\Executables\Docks\G4\firmware.exe"
    $dislink = Resolve-Path ".\Scripts\Executables\Common\DisplayLink*.exe"
    $ethernet = Resolve-Path ".\Scripts\Executables\Docks\G4\Ethernet*.exe"

    # Starting with dock firmware update
    Start-Process -FilePath $dock
    Start-Process -FilePath $ethernet -Wait
    # Updating DisplayLink
    Start-Process -FilePath $dislink
    
}