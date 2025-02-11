
# Need to be able to 'tail' some of the more common logs for troubleshooting (first 50 lines?). 
# Common logs are: System log, Application log, and security 

function Get-AppLogsByNumber {
    param (
        [int] $maxEvents
    )
    $machine_name = $env:COMPUTERNAME
    # Need to save to an appropriate file in Results folder
    Get-WinEvent -LogName "Application" -ComputerName 'localhost' -MaxEvents $maxEvents | ConvertTo-Html -As List | Out-File ".\Results\$($machine_name)-Application.htm"
    
}

function Get-SecLogsByNumber {
    param (
        [int] $maxEvents
    )
    $machine_name = $env:COMPUTERNAME
    # Need to save to an appropriate file in Results folder
    Get-WinEvent -LogName "Security" -ComputerName 'localhost' -MaxEvents $maxEvents | ConvertTo-Html -As List | Out-File ".\Results\$($machine_name)-Security.htm"
}

function Get-SysLogsByNumber {
    param (
        [int] $maxEvents
    )
    $machine_name = $env:COMPUTERNAME
    # Need to save to an appropriate file in Results folder
    Get-WinEvent -LogName "System" -ComputerName 'localhost' -MaxEvents $maxEvents | ConvertTo-Html -As List | Out-File ".\Results\$($machine_name)-System.htm"
    
}

function Get-DumpFiles {
    # Need to pull .dmp files as well if they exist in the machine. Will help for analysis if needed. 
    # Need to save to an appropriate file in Results folder

    # Need to give user a message stating that the latest one is at the bottom of this list. 
    $machine_name = $env:COMPUTERNAME
    Get-ChildItem -Path "C:\Windows" -Filter "*.dmp" -Recurse | ConvertTo-Html -As List | Out-File ".\Results\$($machine_name)-dump_Locations.htm"
}

function Backup-DumpFiles {
    $machine_name = $env:COMPUTERNAME
    # Copy all .dmp files in C:\Windows and its subdirectories
    Robocopy C:\Windows\ ".\Results\$($machine_name)_dumps" *.dmp /S /MT

}

function Show-LogMenu {
    $Selections = @()

    $Selections += [KeySelection]::new('1', "Get recent Application logs",
                        {   [PowerIO]::DisplayText('&[green]Getting Application logs')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            # Checking to see if the user is inputting an INT before actioning. 
                            $inputValue = 0
                            do {
                                $inputValid = [int]::TryParse((Read-Host 'Please enter the number of entries you would like to view from the log'), [ref] $inputValue)
                                if (-not $inputValid) {
                                    Write-Host "The input was not a valid integer. Please try again." -ForegroundColor Red
                                }
                            } while (
                                -not $inputValid
                            )
                            Get-AppLogsByNumber $inputValue
                            Write-Host 'Information saved in the Results folder under (machine name)-Application.htm' -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host });

    $Selections += [KeySelection]::new('2', "Get recent Security logs",
                        {   [PowerIO]::DisplayText('&[green]Getting Security logs')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            # Checking to see if the user is inputting an INT before actioning. 
                            $inputValue = 0
                            do {
                                $inputValid = [int]::TryParse((Read-Host 'Please enter the number of entries you would like to view from the log'), [ref] $inputValue)
                                if (-not $inputValid) {
                                    Write-Host "The input was not a valid integer. Please try again." -ForegroundColor Red
                                }
                            } while (
                                -not $inputValid
                            )
                            Get-SecLogsByNumber $inputValue
                            Write-Host 'Information saved in the Results folder under (machine name)-Security.htm' -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host });

    $Selections += [KeySelection]::new('3', "Get recent System logs",
                        {   [PowerIO]::DisplayText('&[green]Getting System logs')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            # Checking to see if the user is inputting an INT before actioning. 
                            $inputValue = 0
                            do {
                                $inputValid = [int]::TryParse((Read-Host 'Please enter the number of entries you would like to view from the log'), [ref] $inputValue)
                                if (-not $inputValid) {
                                    Write-Host "The input was not a valid integer. Please try again." -ForegroundColor Red
                                }
                            } while (
                                -not $inputValid
                            )
                            Get-SysLogsByNumber $inputValue
                            Write-Host 'Information saved in the Results folder under (machine name)-System.htm' -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host });

    $Selections += [KeySelection]::new('4', "Get Application, Security, and System logs",
                        {   [PowerIO]::DisplayText('&[green]Getting Application, Security, and System logs')

                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            # Checking to see if the user is inputting an INT before actioning. 
                            $inputValue = 0
                            do {
                                $inputValid = [int]::TryParse((Read-Host 'Please enter the number of entries you would like to view from the log'), [ref] $inputValue)
                                if (-not $inputValid) {
                                    Write-Host "The input was not a valid integer. Please try again." -ForegroundColor Red
                                }
                            } while (
                                -not $inputValid
                            )
                            Get-AppLogsByNumber $inputValue
                            Get-SecLogsByNumber $inputValue
                            Get-SysLogsByNumber $inputValue
                            Write-Host 'Information saved under the machine name with respective log type in the Results folder.' -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host });

    $Selections += [KeySelection]::new('5', "Get dump file locations",
                        {   [PowerIO]::DisplayText('&[green]Getting dump file locations from within the Windows folder. Details can be used for further investigations')
                            Write-Host '.' -ForegroundColor Green
                            Write-Host 'Files copied with their original folder structures.' -ForegroundColor Green
                            Get-DumpFiles
                            Backup-DumpFiles
                            Write-Host 'Information saved under (machine name)-dump_Locations.htm in the Results folder along with copies of dump files for review.' -ForegroundColor Green
                            Start-Sleep -Seconds 1.5
                            Clear-Host });

    $PreviousMenuSelection = [KeySelection]::new('q', "&[yellow]Previous menu",
                        { Clear-Host });
    $Selections += $PreviousMenuSelection

    
    $Selection = $null
    while ($Selection -eq $null -or $Selection.Key -ne $PreviousMenuSelection.Key) {
        $Selection = QueryUserKeySelection -Question "&[yellow;darkgray] Please choose an option &[]`n" -Selections $Selections
        $Selection.Run()
    } 
}