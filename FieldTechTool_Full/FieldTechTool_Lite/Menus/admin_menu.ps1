# Menu for common user administration tasks.

# Imports
. .\Scripts\Administration\DPLink_HPIA_Final_Updates.ps1
. .\Scripts\Administration\robocopy.ps1
. .\Scripts\Administration\840_G9_add.ps1
. .\Scripts\Administration\GPU_driver_detection.ps1
function Show-AdminMenu {
    $toolRootDirectory = Resolve-Path .
    do {
        Write-Host '1. DisplayLink, Graphics, HPIA, and trigger Final Updates'
        Write-Host '2. Backup user data with Robocopy'
        Write-Host '3. Disable Sleep and Hibernation on this machine'
        Write-Host "4. Jack's script for 840 G9 (Intel) Autopilot join"
        Write-Host "5. Check for GPU Driver Update"
        Write-Host 'q. Previous menu'
        $choice = Read-Host 'Please choose an option'
        switch ($choice.ToLower()) {
            '1' { 
                Write-Host 'Triggered DisplayLink, HPIA, trigger Final Updates' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Update-Common
             }
             '2'{ 
                Write-Host 'Triggered Robocopy script' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Invoke-RoboCopy
                Set-Location $toolRootDirectory
                Clear-Host
             }
             '3' {
                Disable-Sleep
             }
             '4' {
                Write-Host "Triggered Jack's special script! Will require NuGet provider module. Please accept installation when prompted (Yes, we know the repo is untrusted)!" -ForegroundColor Cyan
                Start-Sleep -Seconds 1.5
                Get-JackInfo
                Clear-Host
             }
             '5' {
                Write-Host "Triggered GPU Driver Update Check" -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host

                # Display driver options to user
                ProvideUserGPUDriverOptions

                Read-Host "`nPress enter to continue...";
                Clear-Host

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