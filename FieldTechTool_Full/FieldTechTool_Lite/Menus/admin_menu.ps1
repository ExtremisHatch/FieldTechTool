# Menu for common user administration tasks.

# Imports
. .\Scripts\Administration\DPLink_HPIA_Final_Updates.ps1
. .\Scripts\Administration\robocopy.ps1
. .\Scripts\Administration\840_G9_add.ps1
. .\Scripts\Administration\GPU_driver_detection.ps1
. .\Scripts\Administration\usb_activate.ps1
function Show-AdminMenu {
    $toolRootDirectory = Resolve-Path .
    
    $Selections = @()

    $Selections += [KeySelection]::new('1', "&[green]DisplayLink, Graphics, HPIA, and trigger Final Updates",
                        {   [PowerIO]::DisplayText('&[green]Triggered &[highlight]DisplayLink, HPIA, trigger Final Updates')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Update-Common });
                            
    $Selections += [KeySelection]::new('2', "&[green]Backup user data with Robocopy",
                        {   [PowerIO]::DisplayText('&[green]Triggered &[highlight]Robocopy script')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Invoke-RoboCopy
                            Set-Location $toolRootDirectory
                            Clear-Host });

    $Selections += [KeySelection]::new('3', "&[green]Disable Sleep and Hibernation on this machine",
                        {   Disable-Sleep });

    $Selections += [KeySelection]::new('4', "&[green]Jack's script for 840 G9 (Intel) Autopilot join",
                        {   [PowerIO]::DisplayText("&[green]Triggered &[highlight]Jack's special script!`n&[gray]Will require NuGet provider module. Please accept installation when prompted (&[highlight]Yes, we know the repo is untrusted&[gray])!")
                            Start-Sleep -Seconds 3 # Increased time for longer message reading
                            Get-JackInfo
                            Clear-Host });

    $Selections += [KeySelection]::new('5', "&[green]Check for GPU Driver Update",
                        {   [PowerIO]::DisplayText("&[green]Triggered &[highlight]GPU Driver Update Check")
                            Start-Sleep -Seconds 1.5
                            Clear-Host

                            # Display driver options to user
                            ProvideUserGPUDriverOptions

                            PauseUser
                            Clear-Host });

    $Selections += [KeySelection]::new('6', "&[green]Check or Enable USB access (will be cleared by policy eventually)",
                        {   [PowerIO]::DisplayText("&[green]Triggered &[highlight]USB access toggling")
                            Start-Sleep -Seconds 1.5
                            Clear-Host

                            # Toggle USB access
                            Enable_USB

                            PauseUser
                            Clear-Host });

    $PreviousMenuSelection = [KeySelection]::new('q', "&[yellow]Previous menu",
                        {   Clear-Host });
    $Selections += $PreviousMenuSelection

    $Selection = $null
    while ($Selection -eq $null -or $Selection.Key -ne $PreviousMenuSelection.Key) {
        $Selection = QueryUserKeySelection -Question "&[yellow;darkgray] Please choose an option &[]`n" -Selections $Selections
        $Selection.Run()
    }
}