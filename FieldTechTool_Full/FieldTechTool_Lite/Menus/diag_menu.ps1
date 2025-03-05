# Menu for gathering system information and running common diagnostic tools including methods to 
# reasonability stress test a system.

# Imports
. .\Scripts\Diagnostics\Simulate_Usage.ps1
. .\Scripts\Diagnostics\gather_logs.ps1
. .\Scripts\Diagnostics\user_usage.ps1
. .\Scripts\Diagnostics\network_queries.ps1

$TriggerText = { param($Text) [CornerStyle]::ROUND.StyleText($Text).Display() }

function Show-DiagMenu {
    $Selections = @()

    $Selections += [KeySelection]::new('1', "&[green]Gather summary info like PC name, IP, OS, etc.",
                        {   $TriggerText.Invoke('&[green]Gathering summary info')
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
                                }" });
                            
    $Selections += [KeySelection]::new('2', "&[green]Run a user simulation on the system **Output in Results folder**",
                        {   $TriggerText.Invoke('&[green]Triggered &[highlight]user simulation')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Invoke-SimulatorController });

    $Selections += [KeySelection]::new('3', "&[green]Gather system logs. **Output in Results folder**",
                        {   $TriggerText.Invoke('&[green]Triggered &[highlight]Triggered system logs')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            Show-LogMenu });

    $Selections += [KeySelection]::new('4', "&[green]Query Users Last Desktop Usage",
                        {   # This can be made to run separate like above, just doing basic implementation (for now?)
                            $TriggerText.Invoke('&[green]Querying users desktop usage')
                            Start-Sleep -Seconds 1.5
                            Clear-Host

                            $UserData = GetLastDesktopAccess

                            [PowerIO]::DisplayText("&[yellow;darkgray] Last User Usage List `n")
                            
                            # Get Max Length username so we can align all dates neatly
                            $MaxLength = ($UserData.UserName | Measure-Object -Property Length -Maximum).Maximum
                            
                            foreach ($User in $UserData) {
                                $PadAmount = $MaxLength - $User.UserName.Length
                                [PowerIO]::DisplayText("&[white;darkgray]$($User.UserName)&[]$(" " * $PadAmount) | &[white;darkgray]$($User.LastAccess.ToString("hh:mm:ss tt dd/MM/yyyy"))")
                            }

                            PauseUser
                            Clear-Host });

    $Selections += [KeySelection]::new('5', "&[green]Check Drives for usage in the last 180 days",
                        {   # Same as above, unsure on how to best implement for I.T usage
                            # May be a good candidate for the separate process workflow as seen for Summary Info
                            $TriggerText.Invoke('&[green]Querying local drives for usage')
                            Start-Sleep -Seconds 1.5
                            Clear-Host

                            [PowerIO]::DisplayText("&[gray]Please wait as drives are scanned... (May take a couple minutes)")

                            # Unsure of I.T's policy or requirements, defaulting to 180 days
                            $DaysSince = 180
                            $LastDriveUsage = GetLastDriveUsage -SinceDate ([DateTime]::Now).AddDays(-($DaysSince))
                            
                            # Make it pretty :)
                            $TimeTaken = ($LastDriveUsage.TimeElapsed.TotalMilliseconds/1000).ToString("#.##")
                            
                            [PowerIO]::DisplayText("&[green]Finished scanning in &[yellow]$TimeTaken&[green] seconds")

                            if ($LastDriveUsage.LastUsage -eq $null) {
                                [PowerIO]::DisplayText("&[red]No usage found in the last &[yellow]$DaysSince &[red]days!")
                            } else {
                                $ModifiedFile = $LastDriveUsage.File

                                [PowerIO]::DisplayText("&[green]Found usage in the last &[yellow]$DaysSince &[green]days: ")
                                [PowerIO]::DisplayText("`t&[yellow]File Modified: &[white;darkgray]$($ModifiedFile.FullName)")
                                [PowerIO]::DisplayText("`t&[yellow]Modified At: &[white;darkgray]$($ModifiedFile.LastWriteTime.ToString('hh:mm:ss tt dd/MM/yyyy'))")
                            }

                            PauseUser
                            Clear-Host });

    $Selections += [KeySelection]::new('6', "&[green]Query remote Desktop/Server Status & User List",
                        {   $TriggerText.Invoke('&[green]Triggered &[highlight]Remote Desktop Query')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            
                            StartRemoteDesktopQuerying

                            PauseUser
                            Clear-Host

                        });

    $Selections += [KeySelection]::new('7', "&[green]Ping Access Point (Test Local Connection)",
                        {   $TriggerText.Invoke('&[green]Triggered &[highlight]Local Connection Test')
                            Start-Sleep -Seconds 1.5
                            Clear-Host
                            
                            StartAccessPointQuerying

                            PauseUser
                            Clear-Host

                        });

    $PreviousMenuSelection = [KeySelection]::new('q', "&[yellow]Previous menu",
                        {   Clear-Host });
    $Selections += $PreviousMenuSelection

    $Selection = $null
    while ($Selection -eq $null -or $Selection.Key -ne $PreviousMenuSelection.Key) {
        $Selection = QueryUserKeySelection -Question ([BoxStyle]::Create([BoxStyle]::THIN, 'yellow').StyleText("&[yellow;darkgray] Please choose an option ")) -Selections $Selections
        $Selection.Run()
    }
}