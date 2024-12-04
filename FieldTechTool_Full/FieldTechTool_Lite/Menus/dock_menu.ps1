# Menu for the HP installation files for docks. Includes neccessary updates to ethernet and USB. 

# Imports
. .\Scripts\Docks\G2\update_G2.ps1
. .\Scripts\Docks\G3_Monitor\update-G3.ps1
. .\Scripts\Docks\G4\update_G4.ps1
. .\Scripts\Docks\G5\update_G5.ps1
function Show-DockMenu {
    do {
        Write-Host "1. G2 Dock firmware/USB update with DisplayLink"
        Write-Host "2. G3 Dock monitor firmware/USB update with DisplayLink"
        Write-Host "3. G4 Dock firmware/USB update with DisplayLink"
        Write-Host "4. G5 Dock firmware/USB update with DisplayLink"
        Write-Host "q. Previous menu"
        $choice = Read-Host 'Please choose an option'
        switch ($choice.ToLower()) {
            '1' {
                Write-Host 'Triggered G2 Dock firmware/USB update with DisplayLink' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Update-G2
             }
             '2' {
                Write-Host 'Triggered G3 Dock monitor firmware/USB update with DisplayLink' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Update-G3
             }
             '3' {
                Write-Host 'Triggered G4 Dock firmware/USB update with DisplayLink' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Update-G4
             }
             '4' {
                Write-Host 'Triggered G5 Dock firmware/USB update with DisplayLink' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Update-G5

             }
             'q' {
                Clear-Host
                break
             }
            Default {
                Write-Host 'Invalid option, please try again' -ForegroundColor Red
                Start-Sleep -Seconds 1.5
                Clear-Host
            }
        }
    } while (
        $choice -ne 'q'
    )
    
}