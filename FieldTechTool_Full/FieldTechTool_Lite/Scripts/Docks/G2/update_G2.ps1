

function Update-G2 {
    Write-Host "Updating G2 dock firmware and DisplayLink afterwards"
    $dock = Resolve-Path ".\Scripts\Executables\Docks\G2\Dock*.exe"
    $ethernet = Resolve-Path ".\Scripts\Executables\Docks\G2\Ethernet*.exe"
    $disLink = Resolve-Path ".\Scripts\Executables\Common\DisplayLink*.exe"

    # Dock and Ethernet firmware can be done at once
    Start-Process -FilePath $dock
    Start-Process -FilePath $ethernet -Wait
    # Waits until firmware updates complete and updates DisplayLink to work with new firmware
    Start-Process -FilePath $disLink
    
}