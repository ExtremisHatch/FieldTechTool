
function Update-Common {
    [PowerIO]::DisplayText("&[green]Updating DisplayLink, HPIA, and Dedicated graphics (for CADs). Final updates will be triggered last")

    $disLink = Resolve-Path '.\Scripts\Executables\Common\DisplayLink*.exe'
    $hpia = Resolve-Path '.\Scripts\Executables\Common\hp-hp*.exe'

    # Ask the user if this is a remote desktop. If it is, confirm if they want to disable sleep and hibernation
    $remoteDesktop = QueryUser -AnswerRequired -Question "Is this a remote desktop? (&[green]Y&[]/&[red]N&[])"
    if ($remoteDesktop -eq "Y") {
        Disable-Sleep
    }

    # DisplayLink and HPIA can run at the same time without conflicting
    # Start-Process -FilePath $disLink
    if (Test-Path -Path ".\Scripts\Executables\Add-ons") {
        Install-Graphics
    }
    
    $answer = Read-Host "Is this an HP device? Enter Y or y only. Otherwise, HPIA won't run if you want it to."
    if (($answer -match 'y') -or ($answer -match 'Y')) {
        Start-Process -FilePath $hpia -Wait
    }
    
    Clear-Host
    # Waits until HPIA is done and triggers Windows Update
    Start-Process -FilePath 'ms-settings:windowsupdate'
    
}

# Need to rework this section using 'Supported Products' on the release screen. These can be condensed as more than one model may be supported with a single, latest driver. 
# Uses Add-ons folder to check for dedicated graphics and run the appropriate driver update
function Install-Graphics {
    $GPU_Intensive = Resolve-Path ".\Scripts\Executables\Add-ons\Graphics\GPU_intensive_leased_machine\*.exe"
    $Studio_10 = Resolve-Path ".\Scripts\Executables\Add-ons\Graphics\ZBook_Studio_G10\*.exe"
    [PowerIO]::DisplayText("&[green]Checking for dedicated graphics prior to running HPIA")
    # Getting Graphics info from machine. Integrated and Dedicated
    $videoControllers = Get-CimInstance -ClassName Win32_VideoController

    $Studio_10_GPUs = @("*RTX 2000*", "*RTX A500*", "*RTX A2000*")
    $GPU_Intensive_GPUs = @("*RTX 2070*","*RTX A4000*","*Quadro T2000*","*RTX 2080*")

    # Flaw in this is that most devices have onboard graphics alongside dedicated
    # This for each graphics device, meaning users will almost always get a second message stating
    # "No dedicated graphics detected" etc
    foreach ($vc in $videoControllers){
        if (($Studio_10_GPUs | Where-Object { $vc.Name -like $_ }) -ne $null) {
                [PowerIO]::DisplayText("&[yellow]Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation.")
                [PowerIO]::DisplayText("&[yellow]Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs.")
                Start-Process -FilePath $Studio_10
        } elseif (($GPU_Intensive_GPUs | Where-Object { $vc.Name -like $_ }) -ne $null) {
                [PowerIO]::DisplayText("&[yellow]Dedicated Graphics detected. Running driver update. Please ensure that you select a clean installation.")
                [PowerIO]::DisplayText("&[yellow]Make sure to unselect the Nvidia Driver that HPIA will try to install when it runs.")
                Start-Process -FilePath $GPU_Intensive
        } else { # Need to make one more for the GPU intensive one. It should be something with RTX2080 in it. 
                [PowerIO]::DisplayText("&[green]No dedicated graphics detected. Continuing with HPIA.")
        }
    }
}

# Turn off sleep and hibernation for remote desktops
function Disable-Sleep {
    [PowerIO]::DisplayText("&[green]Turning &[highlight]off&[green] sleep and hibernation. Primarily for remote desktops")
    powercfg -change -standby-timeout-ac 0
    powercfg -change -hibernate-timeout-ac 0
    powercfg -change -monitor-timeout-ac 0
    powercfg -change -disk-timeout-ac 0
    [PowerIO]::DisplayText("&[green]Sleep and hibernation have been &[red;highlight]disabled")
    Start-Sleep -Seconds 3
}