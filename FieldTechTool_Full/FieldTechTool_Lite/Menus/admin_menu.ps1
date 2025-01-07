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
                        {   Write-Host 'Triggered DisplayLink, HPIA, trigger Final Updates' -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Update-Common });
                            
    $Selections += [KeySelection]::new('2', "&[green]Backup user data with Robocopy",
                        {   Write-Host 'Triggered Robocopy script' -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Invoke-RoboCopy
                            Set-Location $toolRootDirectory
                            Clear-Host });

    $Selections += [KeySelection]::new('3', "&[green]Disable Sleep and Hibernation on this machine",
                        {   Disable-Sleep });

    $Selections += [KeySelection]::new('4', "&[green]Jack's script for 840 G9 (Intel) Autopilot join",
                        {   Write-Host "Triggered Jack's special script! Will require NuGet provider module. Please accept installation when prompted (Yes, we know the repo is untrusted)!" -ForegroundColor Cyan
                            Start-Sleep -Seconds 1.5
                            Get-JackInfo
                            Clear-Host });

    $Selections += [KeySelection]::new('5', "&[green]Check for GPU Driver Update",
                        {   Write-Host "Triggered GPU Driver Update Check" -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host

                            # Display driver options to user
                            ProvideUserGPUDriverOptions

                            Read-Host "`nPress enter to continue...";
                            Clear-Host });

    $Selections += [KeySelection]::new('6', "&[green]Check or Enable USB access (will be cleared by policy eventually)",
                        {   Write-Host "Triggered USB access toggling" -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            # Toggle USB access
                            Enable_USB
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