# Main menu and primary application loop.

# Imports
. .\Menus\dock_menu.ps1
. .\Menus\admin_menu.ps1
. .\Menus\diag_menu.ps1

function Show-MainMenu {
    # show a selection of options to choose from
    $Selections = @()

    $Selections += [KeySelection]::new('1', "&[white;darkred]User Administration",
                        {   Write-Host "Navigating to User Administration menu" -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Show-AdminMenu });

    $Selections += [KeySelection]::new('2', "&[green]Machine Diagnostics",
                        {   Write-Host "Navigating to Diagnostic menu" -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Show-DiagMenu })

    $Selections += [KeySelection]::new('3', "&[green]Dock Menu",
                        {   Write-Host "Navigating to Dock menu." -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Show-DockMenu })

    $Selections += [KeySelection]::new('t', "&[white;darkgray]Toggle Lite/Full mode", 
                        {   if (Test-Path -Path "..\Add-ons\") {
                                Write-Host "Switching to Full version" -ForegroundColor Green
                                Move-Item ..\Add-ons\ .\Scripts\Executables\
                                Clear-Host
                                Write-Host "Using Full Version" -ForegroundColor Green
                            }
                            elseif (Test-Path -Path ".\Scripts\Executables\Add-ons") {
                                Write-Host "Switching to Lite version" -ForegroundColor Green
                                Move-Item .\Scripts\Executables\Add-ons\ ..\
                                Clear-Host
                                Write-Host "Using Lite Version" -ForegroundColor Green
                            }
                            else {
                                Write-Host "Add-ons package not in Full version folder. This needs to be placed in the proper folder" -ForegroundColor Red
                                Start-Sleep -Seconds 1.5
                                Clear-Host
                            }
                        })

    $Selections += [KeySelection]::new('q', "&[red]Exit",
                        {   Write-Host "See you later!" -ForegroundColor Yellow
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            exit})
    
    $Selections += [KeySelection]::new('rm', "&[white;darkred]Erase all files and folders in this directory for cleanup",
                        {   Write-Host "Erasing this application's folder and contents" -ForegroundColor Red
                            Write-Host "Are you sure? (y/n)"
                            $erase = Read-Host "Enter your choice"
                            if ($erase -eq 'y') {
                                Write-Host "Erasing all files and folders in this directory and exiting." -ForegroundColor Red
                                Start-Sleep -Seconds 1.5
                                Clear-Host
                                Remove-Item -Path .\* -Recurse -Force
                                exit
                            }
                            else {
                                Write-Host "Returning to main menu" -ForegroundColor Green
                                Start-Sleep -Seconds 1.5
                                Clear-Host
                            }
                        })
   
   while ($true) {
        $Selection = QueryUserKeySelection -Question "&[yellow;darkgray] What would you like to do? &[]`n" -Selections $Selections
        $Selection.Run()
   }
}