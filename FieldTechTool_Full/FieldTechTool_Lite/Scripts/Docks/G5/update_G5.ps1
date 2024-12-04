

function Update-G5 {
    Write-Host "Updating G5 dock firmware and DisplayLink afterwards."
    $dock = Resolve-Path '.\Scripts\Executables\Docks\G5\Dock*.exe'
    $ethernet = Resolve-Path ".\Scripts\Executables\Docks\G5\Ethernet*.exe"
    $dislink = Resolve-Path ".\Scripts\Executables\Common\DisplayLink*.exe"
    
    # Dock and Ethernet firmware can be done at once
    Start-Process -FilePath $dock
    Start-Process -FilePath $ethernet -Wait
    # Waits until firmware updates complete and updates DisplayLink to work with new firmware
    Start-Process -FilePath $disLink
}