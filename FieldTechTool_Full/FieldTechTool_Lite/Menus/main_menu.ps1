# Main menu and primary application loop.

# Imports
. .\Menus\dock_menu.ps1
. .\Menus\admin_menu.ps1
. .\Menus\diag_menu.ps1

function Show-MainMenu {
    # show a selection of options to choose from
    $Selections = @()

    $Selections += [KeySelection]::new('1', "&[white;red]User Administration",
                        {   [PowerIO]::DisplayText("&[green]Navigating to User Administration menu")
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Show-AdminMenu });

    $Selections += [KeySelection]::new('2', "&[green]Machine Diagnostics",
                        {   [PowerIO]::DisplayText("&[green]Navigating to Diagnostic menu")
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Show-DiagMenu })

    $Selections += [KeySelection]::new('3', "&[green]Dock Menu",
                        {   [PowerIO]::DisplayText("&[green]Navigating to Dock menu.")
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Show-DockMenu })

    $Selections += [KeySelection]::new('t', "&[white;darkgray]Toggle Lite/Full mode", 
                        {   if (Test-Path -Path "..\Add-ons\") {
                                [PowerIO]::DisplayText("&[green]Switching to Full version")
                                Move-Item ..\Add-ons\ .\Scripts\Executables\
                                Clear-Host
                                [PowerIO]::DisplayText("&[green]Using Full Version")
                            }
                            elseif (Test-Path -Path ".\Scripts\Executables\Add-ons") {
                                [PowerIO]::DisplayText("&[green]Switching to Lite version")
                                Move-Item .\Scripts\Executables\Add-ons\ ..\
                                Clear-Host
                                [PowerIO]::DisplayText("&[green]Using Lite Version")
                            }
                            else {
                                [PowerIO]::DisplayText("&[red]Add-ons package not in Full version folder. This needs to be placed in the proper folder")
                                Start-Sleep -Seconds 1.5
                                Clear-Host
                            }
                        })

    $ExitSelection = [KeySelection]::new('q', "&[red]Exit",
                        {   [PowerIO]::DisplayText("&[yellow]See you later!")
                            Start-Sleep -Seconds 1.5
                            Clear-Host })
    $Selections += $ExitSelection

    $Selections += [KeySelection]::new('rm', "&[white;darkred]Erase all files and folders in this directory for cleanup",
                        {   [PowerIO]::DisplayText("&[red]Erasing this application's folder and contents")
                            [PowerIO]::DisplayText("&[yellow]Are you sure?")
                            $erase = QueryUser -AnswerRequired -Question "Enter your choice (&[green]y&[]/&[red]n&[])"
                            if ($erase -eq 'y') {
                                [PowerIO]::DisplayText("&[red]Erasing all files and folders in this directory and exiting.")
                                Start-Sleep -Seconds 1.5
                                Clear-Host
                                Remove-Item -Path .\* -Recurse -Force
                                exit
                            }
                            else {
                               [PowerIO]::DisplayText("&[green]Returning to main menu")
                                Start-Sleep -Seconds 1.5
                                Clear-Host
                            }
                        })
   
   $Selection = $null;
   # While Selection doesn't exist (First iteration), or Selection isn't "Exit" (Q), keep looping
   while ($Selection -eq $null -or $Selection.Key -ne $ExitSelection.Key) {
        $Selection = QueryUserKeySelection -Question ([BoxStyle]::Create([BoxStyle]::THIN, 'yellow').StyleText("&[yellow;darkgray] What would you like to do? ")) -Selections $Selections
        $Selection.Run()
   }
}