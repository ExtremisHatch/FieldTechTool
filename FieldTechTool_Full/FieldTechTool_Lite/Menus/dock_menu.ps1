# Menu for the HP installation files for docks. Includes neccessary updates to ethernet and USB. 

# Imports
. .\Scripts\Docks\G2\update_G2.ps1
. .\Scripts\Docks\G3_Monitor\update-G3.ps1
. .\Scripts\Docks\G4\update_G4.ps1
. .\Scripts\Docks\G5\update_G5.ps1

$TriggerText = { param($Text) [CornerStyle]::ROUND.StyleText($Text).Display() }

function Show-DockMenu {
    $Selections = @()

    $Selections += [KeySelection]::new('1', "&[green]G2 Dock firmware/USB update with DisplayLink",
                        {   $TriggerText.Invoke('&[green]Triggered &[highlight]G2 Dock firmware/USB update with DisplayLink')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Update-G2 });
                            
    $Selections += [KeySelection]::new('2', "&[green]G3 Dock monitor firmware/USB update with DisplayLink",
                        {   $TriggerText.Invoke('&[green]Triggered &[highlight]G3 Dock monitor firmware/USB update with DisplayLink')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Update-G3 });

    $Selections += [KeySelection]::new('3', "&[green]G4 Dock firmware/USB update with DisplayLink",
                        {   $TriggerText.Invoke('&[green]Triggered &[highlight]G4 Dock firmware/USB update with DisplayLink')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Update-G4 });

    $Selections += [KeySelection]::new('4', "&[green]G5 Dock firmware/USB update with DisplayLink",
                        {   $TriggerText.Invoke('&[green]Triggered &[highlight]G5 Dock firmware/USB update with DisplayLink')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Update-G5 });

    $PreviousMenuSelection = [KeySelection]::new('q', "&[yellow]Previous menu",
                        {   Clear-Host });
    $Selections += $PreviousMenuSelection

    $Selection = $null
    while ($Selection -eq $null -or $Selection.Key -ne $PreviousMenuSelection.Key) {
        $Selection = QueryUserKeySelection -Question ([BoxStyle]::Create([BoxStyle]::THIN, 'yellow').StyleText("&[yellow;darkgray] Please choose an option ")) -Selections $Selections
        $Selection.Run()
    }
}