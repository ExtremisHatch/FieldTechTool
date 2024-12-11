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

                    # Current GPU Driver Version (Shortened NVidia "Standard" lol)
                    $CurrentVersion = $Device.ShortGPUDriverVersion | % { @{Version=([double]$_);Major=([int]$_.Split('.')[0]);Minor=([int]$_.Split('.')[1])} }
                    
                    # Get the latest available version out of the results, then manipulate into a nice convenient object (Very clean, totally doesn't need a rewrite)
                    $LatestAvailable = ($GPUDrivers.DriverVersion | %{[double]$_} | Sort-Object -Descending | Select-Object -First 1) | `
                                        % { @{Version=$_;Major=([int]$_.ToString().Split('.')[0]);Minor=([int]$_.ToString().Split('.')[1])} }
                    
                    $Outdated = $LatestAvailable.Version -gt $CurrentVersion.Version
                    $OutdatedType = if ($Outdated) { if ($LatestAvailable.Major -gt $CurrentVersion.Major) {"Major"} else {"Minor"} } else { $null }

                    # List out current details for user
                    Write-Host "`nCurrent GPU: $($Device.GPUName)" -ForegroundColor Yellow

                    # If Outdated, don't print new line yet
                    Write-Host "`tDriver Version: $($Device.ShortGPUDriverVersion)" -ForegroundColor Yellow -NoNewline:$Outdated 

                    if ($Outdated) {
                        Write-Host " [Potential $OutdatedType Update Available]" -ForegroundColor Magenta
                    }

                    Write-Host "`nDrivers Available:"
                    for ($i=0; $i -lt $GPUDrivers.Count; $i++) {
                        $Driver = $GPUDrivers[$i]
                        Write-Host "[$($i+1)] $($Driver.ProductName)" -ForegroundColor Yellow
                        Write-Host "`t$($Driver.DriverName) [Version: $($Driver.DriverVersion)]"
                        Write-Host "`tDownload URL [$($Driver.DownloadSize)]: $($Driver.DownloadURL)"
                    }

                    $DownloadDriver = @("Y","YES") -contains (Read-Host "`nWould you like to download a listed GPU Driver? (Y/n)")
                    if ($DownloadDriver) {
                        while (($DriverIndex = Read-Host "Please input the Number of the GPU Driver you wish to download") -ne $null) {
                            # Ensure it's a number
                            if ($DriverIndex -notmatch "^(\d)*$") { continue; }
                            
                            # Cast to Int
                            $DriverIndex = [int]$DriverIndex;

                            # If it's within range, break!
                            if ($DriverIndex -le $GPUDrivers.Count -and $DriverIndex -gt 0) { break; }
                        }

                        # Driver Selected by User
                        $SelectedDriver = $GPUDrivers[$DriverIndex-1]
                        $DownloadURL = $SelectedDriver.DownloadURL

                        # If DownloadURL ends with ".exe", ".app", ".XXX", we will keep the end of the URL as the file name
                        $FileName = if ($DownloadURL -match "\.[a-zA-Z0-9]{2,3}$") { $DownloadURL.Substring($DownloadURL.LastIndexOf('/') + 1) } else {'GPU-Driver.exe'}
                        
                        # Local Output Path
                        $OutputPath = ".\Drivers\"
                        $DriverLocation = "$($OutputPath)$($FileName)"
                        if (-not (Test-Path $OutputPath)) {
                            New-Item -Path $OutputPath -ItemType "Directory" > $null
                        }

                        Write-Host "Downloading `"$($SelectedDriver.ProductName)`" driver [$($SelectedDriver.DownloadSize)]"
                        Write-Host "`tThis may take some time..." -ForegroundColor Gray

                        Invoke-WebRequest -Uri $DownloadURL -OutFile $DriverLocation

                        Write-Host "Download complete!" -ForegroundColor Green
                        Write-Host "Driver Location: $((Get-Item $DriverLocation).FullName)"
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