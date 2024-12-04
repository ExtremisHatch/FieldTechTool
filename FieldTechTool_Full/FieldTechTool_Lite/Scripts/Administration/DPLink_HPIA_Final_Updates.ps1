
function Update-Common {
    Write-Host "Updating DisplayLink, HPIA, and Dedicated graphics (for CADs). Final updates will be triggered last" -ForegroundColor Green

    $disLink = Resolve-Path '.\Scripts\Executables\Common\DisplayLink*.exe'
    $hpia = Resolve-Path '.\Scripts\Executables\Common\hp-hp*.exe'

    # Ask the user if this is a remote desktop. If it is, confirm if they want to disable sleep and hibernation
    $remoteDesktop = Read-Host "Is this a remote desktop? (Y/N)"
    if ($remoteDesktop -eq "Y") {
        Disable-Sleep
    }

    # DisplayLink and HPIA can run at the same time without conflicting
    Start-Process -FilePath $disLink
    if (Test-Path -Path ".\Scripts\Executables\Add-ons") {
        Install-Graphics
    } 
    Start-Process -FilePath $hpia -Wait
    Clear-Host
    # Waits until HPIA is done and triggers Windows Update
    Start-Process -FilePath 'ms-settings:windowsupdate'
    
}

# Need to rework this section using 'Supported Products' on the release screen. These can be condensed as more than one model may be supported with a single, latest driver. 
# Uses Add-ons folder to check for dedicated graphics and run the appropriate driver update
function Install-Graphics {
    $GPU_Intensive = Resolve-Path ".\Scripts\Executables\Add-ons\Graphics\GPU_intensive_leased_machine\*.exe"
    $Studio_10 = Resolve-Path ".\Scripts\Executables\Add-ons\Graphics\ZBook_Studio_G10\*.exe"
    Write-Host "Checking for dedicated graphics prior to running HPIA" -ForegroundColor Green
    # Getting Graphics info from machine. Integrated and Dedicated
    $videoControllers = Get-CimInstance -ClassName Win32_VideoController

    foreach ($vc in $videoControllers){
        switch -Wildcard ($vc.Name) {
             
            "*RTX 2000*" {
                Write-Host "Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation." -ForegroundColor Yellow
                Write-Host "Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs." -ForegroundColor Yellow
                Start-Process -FilePath $Studio_10
            }
              
            "*RTX A500*" {
                Write-Host "Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation." -ForegroundColor Yellow
                Write-Host "Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs." -ForegroundColor Yellow
                Start-Process -FilePath $Studio_10
            }
             
            "*RTX A2000*" {
                Write-Host "Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation." -ForegroundColor Yellow
                Write-Host "Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs." -ForegroundColor Yellow
                Start-Process -FilePath $Studio_10
            }
             
            "*RTX 2070*" {
                Write-Host "Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation." -ForegroundColor Yellow
                Write-Host "Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs." -ForegroundColor Yellow
                Start-Process -FilePath $GPU_Intensive
            }
              
            "*RTX A4000*" {
                Write-Host "Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation." -ForegroundColor Yellow
                Write-Host "Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs." -ForegroundColor Yellow
                Start-Process -FilePath $Studio_10
            }
             
            "*Quadro T2000*" {
                Write-Host "Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation." -ForegroundColor Yellow
                Write-Host "Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs." -ForegroundColor Yellow
                Start-Process -FilePath $Studio_10
            }
             
            "*RTX 2080*" {
                Write-Host "Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation." -ForegroundColor Yellow
                Write-Host "Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs." -ForegroundColor Yellow
                Start-Process -FilePath $GPU_Intensive
            }
            # Need to make one more for the GPU intensive one. It should be something with RTX2080 in it. 
            default {
                Write-Host "No dedicated graphics detected. Continuing with HPIA." -ForegroundColor Green
            }
        }
    }
    
}

# Turn off sleep and hibernation for remote desktops
function Disable-Sleep {
    Write-Host "Turning off sleep and hibernation. Primarily for remote desktops" -ForegroundColor Green
    powercfg -change -standby-timeout-ac 0
    powercfg -change -hibernate-timeout-ac 0
    powercfg -change -monitor-timeout-ac 0
    powercfg -change -disk-timeout-ac 0
    Write-Host "Sleep and hibernation have been disabled" -ForegroundColor Green
    Start-Sleep -Seconds 3
}