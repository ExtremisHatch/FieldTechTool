# Menu for gathering system information and running common diagnostic tools including methods to 
# reasonability stress test a system.

# Imports
. .\Scripts\Diagnostics\Simulate_Usage.ps1
. .\Scripts\Diagnostics\gather_logs.ps1
. .\Scripts\Diagnostics\user_usage.ps1

function Show-DiagMenu {
    do {
        Write-Host '1. Gather summary info like PC name, IP, OS, etc.'
        Write-Host '2. Run a user simulation on the system **Output in Results folder**'
        Write-Host '3. Gather system logs. **Output in Results folder**'
        Write-Host '4. Query Users Last Desktop Usage'
        Write-Host '5. Check Drives for usage in the last 180 days'
        Write-Host 'q. Previous menu'
        $choice = Read-Host 'Please choose an option'
        switch ($choice.ToLower()) {
            '1' { 
                Write-Host 'Gathering summary info' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                # An example of running an ad-hoc function in a separate process and ensuring no other commmands are supplied to possible elevated prompt
                # NoExit flag allows main program to continue after calling
                # '& {script block (note semicolons)}' is supplied to the Command flag of the ArgumentList
                Start-Process powershell -ArgumentList "-NoExit", 
                    "-Command", "& { 
                        # Import the Get-SystemSummary function from the machine_summary.ps1 script
                        . .\Scripts\Diagnostics\machine_summary.ps1; 
                        # Execute the imported function to gather system summary information
                        Get-SystemSummary;
                        # Prompt the tech to press enter before closing the new window
                        Read-Host 'Press enter to exit...';
                        # Ensuring new PowerShell window is closed
                        Exit
                    }"
             }
            '2' {
                Write-Host 'Triggered user simulation' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Invoke-SimulatorController
             }
            '3' {
                Write-Host 'Triggered system logs' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Show-LogMenu
             }
            '4' {
                # This can be made to run separate like above, just doing basic implementation (for now?)
                Write-Host 'Querying users desktop usage' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host

                $UserData = GetLastDesktopAccess
                foreach ($User in $UserData) {
                    Write-Host "$($User.UserName): $($User.LastAccess)"
                }

                Read-Host 'Press enter to continue...';
                Clear-Host
             }
            '5' {
                # Same as above, unsure on how to best implement for I.T usage
                # May be a good candidate for the separate process workflow as seen for Summary Info
                Write-Host 'Querying local drives for usage' -ForegroundColor Green
                Start-Sleep -Seconds 1.5
                Clear-Host
                Write-Host "Please wait as drives are scanned... (May take a couple minutes)"

                # Unsure of I.T's policy or requirements, defaulting to 180 days
                $DaysSince = 180
                $LastDriveUsage = GetLastDriveUsage -SinceDate ([DateTime]::Now).AddDays(-($DaysSince))
                
                # Make it pretty :)
                $TimeTaken = ($LastDriveUsage.TimeElapsed.TotalMilliseconds/1000).ToString("#.##")
                
                Write-Host "Finished scanning in $TimeTaken seconds"

                if ($LastDriveUsage.LastUsage -eq $null) {
                    Write-Host "No usage found in the last $DaysSince days!"
                } else {
                    $ModifiedFile = $LastDriveUsage.File

                    Write-Host "Found usage in the last $DaysSince days: "
                    Write-Host "File Modified: $($ModifiedFile.FullName)"
                    Write-Host "Modified At: $($ModifiedFile.LastWriteTime.ToShortDateString())"
                }

                Read-Host 'Press enter to continue...';
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