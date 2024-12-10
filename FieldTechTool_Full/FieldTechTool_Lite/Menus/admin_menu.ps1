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

                # Find Drivers, enable progress output so user doesn't think everything broke
                $GPUDrivers = FindRelevantGPUDrivers -OutputProgress

                if ($GPUDrivers.Count -eq 0) {
                    Write-Host "Couldn't find any Drivers online, this may be an error!"
                } else {
                    Write-Host "Found $($GPUDrivers.Count) potential driver(s)..." -ForegroundColor Gray

                    $Device = GetDriverDeviceInformation
                    Write-Host "`nCurrent GPU Driver Version: $($Device.ShortGPUDriverVersion)" -ForegroundColor Yellow

                    Write-Host "`nDrivers Available:"
                    foreach ($Driver in $GPUDrivers) {
                        Write-Host "$($Driver.ProductName)" -ForegroundColor Yellow
                        Write-Host "`t$($Driver.DriverName) [Version: $($Driver.DriverVersion)]"
                        Write-Host "`tDownload URL [$($Driver.DownloadSize)]: $($Driver.DownloadURL)"
                    }
                }

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