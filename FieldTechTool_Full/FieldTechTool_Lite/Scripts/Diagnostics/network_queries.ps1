﻿class PingUtilities {
    static [String] ColorPing([int]$Ping) {
        if ($Ping -le 100) { return "&[green]${Ping}ms&[]" } elseif ($Ping -le 250) { return "&[yellow]${Ping}ms&[]" } else { return "&[red]${Ping}ms&[]" }
    }

    static [String] ColorSuccessRate([pscustomobject] $PingStats) {
        $Percentage = [double] ($PingStats.SuccessCount / $PingStats.TotalCount)
        $Color = if ($Percentage -gt 0.9) { 'green' } elseif ($Percentage -gt 0.65) { 'yellow' } else { 'red' }
        return $Percentage.ToString("&[$Color]0.#%")
    }

    static [String] ColorVariance([pscustomobject] $PingStats) {
        $Color = if ($PingStats.VariancePercentage -le 0.15) { 'green' } elseif ($PingStats.VariancePercentage -le 0.35) { 'yellow' } else { 'red' }
        return $PingStats.VariancePercentage.ToString("&[$Color]0.#%")
    }

    static [Hashtable] GetStatistics([pscustomobject[]]$Pings) {
        $Result = @{}
        
        $SuccessfulPings = $Pings | Where-Object { $_.Success }

        # Basic Min, Max, Avg
        $Result.Average = [int] ($SuccessfulPings.ResponseTime | Measure-Object -Average).Average
        $Result.Minimum = [int] ($SuccessfulPings.ResponseTime | Measure-Object -Minimum).Minimum
        $Result.Maximum = [int] ($SuccessfulPings.ResponseTime | Measure-Object -Maximum).Maximum
        
        # This calculates the Ping variance in ms
        #  Subtract the Average from each individual ping, square the result, add all results together and average them,
        #   and finally, Square Root that average for the Std Dev
        # To get this as a %, divide by Average Ping
        $Result.Variance = [Math]::Sqrt((($SuccessfulPings | % { [Math]::Pow(($_.ResponseTime - $Result.Average), 2) }) | Measure-Object -Average).Average)
        $Result.VariancePercentage = $Result.Variance / [Math]::Max(1, $Result.Average)

        # Success counts
        $Result.SuccessCount = $SuccessfulPings.Count
        $Result.TotalCount = $Pings.Count
        $Result.FailedCount = $Pings.Count - $SuccessfulPings.Count

        return $Result
    }
}

function StartRemoteDesktopQuerying {
    # Ask user what desktop/server
    $DesktopName = QueryUser -Question "&[Yellow]What Desktop/Server would you like to query?&[]`n>" -AnswerRequired
  
    # Results of Query
    $Result = QueryNetworkMachine -Server $DesktopName -PingCount 10

    #
    # Start the fancy output !
    #

    Write-Host "" # Separator

    [PowerIO]::DisplayText("&[yellow]Status of &[highlight]$DesktopName&[yellow]:")
    [PowerIO]::DisplayText("`t&[Gray]Online: &[$(if($Result.Online){'green'}else{'red'})]$($Result.Online)")
    
    #
    # Ping Information
    #
    
    $PingResults = $Result.Ping
    $PingStatus = if ($PingResults.Success) { "&[green]Successful" } else { "&[red]Failed" }
    
    # Display the Ping Status
    [PowerIO]::DisplayText("`t&[gray]Ping: $PingStatus")

    # If Ping was successful, display ping stats
    if ($PingResults.Success) {
        $PingStats = [PingUtilities]::GetStatistics($PingResults.Pings)

        $ResultsText = "Results: "
        $ResultOffset = "`t`t`t" # Fancy alignment
        [PowerIO]::DisplayText("`t`t&[gray]$ResultsText")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Success Rate: $([PingUtilities]::ColorSuccessRate($PingStats))&[gray] [$($PingStats.SuccessCount)/$($PingStats.TotalCount)]")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Response Time: $([PingUtilities]::ColorPing($PingStats.Average))&[gray] [Min: $([PingUtilities]::ColorPing($PingStats.Minimum))&[gray], Max: $([PingUtilities]::ColorPing($PingStats.Maximum))&[gray]]")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Variance: $([PingUtilities]::ColorVariance($PingStats))&[gray] [+- $($PingStats.Variance.ToString('0.#'))ms]")
    }

    #
    # Desktop/Server User List & Info
    #

    # Uncertain if $Result.Online = $false means no users will show, best just checking if there is users
    # EDIT: If it's online OR User count not 0, show Users
    if ($Result.Online -or $Result.Users.Count -ne 0) {
        [PowerIO]::DisplayText("`t&[Gray]Users: &[green]$($Result.Users.Count)")
    }

    if ($Result.Users.Count -gt 0) {
        $Result.Users | % { 
            
            # Prefix the spacing, as this line is displayed in parts
            [PowerIO]::DisplayText("`t`t", $false)

            # When a user is disconnected there is no session name
            if ($_.SessionName -notlike $null) {
                [PowerIO]::DisplayText("&[white;darkgray]$($_.SessionName): ", $false)
            }
            
            # Color for 'State' value, doing inline made it a bit messy
            $StateColor = if($_.State -like 'Active') {'green'} else {'red'}

            # Display final part of line
            [PowerIO]::DisplayText("&[white;darkgray]$($_.Username) - &[$StateColor;darkgray]$($_.State)&[] &[gray][Id: $($_.Id); Logon: $($_.LogonTime); Idle: $($_.IdleTime)]") 
        }
    }

    Write-Host "" # Newline separator
}

function StartAccessPointQuerying {
    # Filter down to Internet adapters, and only active ones
    $NetworkConfigurations = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne 'Disconnected' }
    $ConfigDescriptors = $NetworkConfigurations | % { "&[yellow]$($_.InterfaceAlias) &[gray]($($_.InterfaceDescription))" }

    if ($NetworkConfigurations.Count -gt 1) {
        $SelectedConfiguration = $NetworkConfigurations[(QueryUserSelection -Question "Which Network Adapter are you using?" -Answers $ConfigDescriptors)]
    } elseif ($NetworkConfigurations.Count -eq 1) {
        $SelectedConfiguration = $NetworkConfigurations[0]
    } else {
        throw "No NetworkConfigurations to test!"
    }

    # Look, I haven't actually found a way to specify the SOURCE Interface/Address
    # Atleast, not with the way I do pings (Superior method anyways lol)
    # But by pinging the gateway, we can only reach it from the desired (or connected) adapter anyway!
    $DefaultGateway = $SelectedConfiguration.IPv4DefaultGateway[0].NextHop

    [PowerIO]::DisplayText("`n&[yellow]Testing '&[hl]$($SelectedConfiguration.InterfaceAlias)&[/hl]', Pinging IPv4 Gateway '&[hl]$DefaultGateway&[/hl]'")
    
    $PingResults = PingServer -Server $DefaultGateway -Count 25
    $PingStatus = if ($PingResults.Success -eq $true) { "&[green]Successful" } else { "&[red]Failed" }
    
    # Display the Ping Status
    # Copypasta from the other method
    [PowerIO]::DisplayText("`t&[gray]Ping: $PingStatus")
    if ($PingResults.Success -eq $true) { # If any succeed
        $PingStats = [PingUtilities]::GetStatistics($PingResults)

        $ResultsText = "Results: "
        $ResultOffset = "`t`t`t" # Fancy alignment
        [PowerIO]::DisplayText("`t`t&[gray]$ResultsText")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Success Rate: $([PingUtilities]::ColorSuccessRate($PingStats))&[gray] [$($PingStats.SuccessCount)/$($PingStats.TotalCount)]")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Response Time: $([PingUtilities]::ColorPing($PingStats.Average))&[gray] [Min: $([PingUtilities]::ColorPing($PingStats.Minimum))&[gray], Max: $([PingUtilities]::ColorPing($PingStats.Maximum))&[gray]]")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Variance: $([PingUtilities]::ColorVariance($PingStats))&[gray] [+- $($PingStats.Variance.ToString('0.#'))ms]")
    }

    Write-Host "" # Newline separator
}

function PingServer {
    param($Server, $Timeout=2000, $Count=10, [switch]$AsJob, [ScriptBlock]$PingEventHandler, [int]$InterPingDelay=50)

    $PingScript = {
        param($Server, $Timeout, $Count)
        $Pings = @() # List of pings
        for ($i = 0; $i -lt $Count; $i++) {
            $StartTime = [DateTime]::Now
            $Ping = (Get-WmiObject -Class Win32_PingStatus -Filter ('Address="{0}" and Timeout={1}' -f $Server, $Timeout) | Select-Object ResponseTime, StatusCode)
            $PingResult = @{Success=($Ping.StatusCode -eq 0);
                            StatusCode=($Ping.StatusCode);
                            ResponseTime=($Ping.ResponseTime);}
            $Pings += $PingResult

            # Ping Event Handler, no idea for use case yet just nifty to have
            if ($PingEventHandler -ne $null) { $PingEventHandler.Invoke($PingResult) }
            
            # Ping spacing
            if (($PassedTime = ($EndTime = [DateTime]::Now).Subtract($StartTime).TotalMilliseconds) -lt $InterPingDelay) {
                Start-Sleep -Milliseconds ($InterPingDelay - $PassedTime) # This way we can force pings to be at LEAST 50ms apart for example
            }
        }
        return $Pings
    }

    if (-not $AsJob) {
        return $PingScript.Invoke($Server, $Timeout, $Count)
    }

    $PingJob = Start-Job -ScriptBlock $PingScript -ArgumentList $Server, $Timeout, $Count
    return $PingJob
}

function QueryNetworkMachine {
    param($Server, $PingTimeout=2000, $PingCount=5)

    $Result = @{Online=$False; Users=@(); Ping=@{Success=$False;Pings=@()}}

    # Before we do anything, start the ping job in the background
    $PingJob = PingServer -Server $Server -Timeout $PingTimeout -Count $PingCount -AsJob

    # Set our EAP so that the 'quser' function actually throws an exception
    $StoredEAP = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    try {
        $Lines = @(quser /server:$Server) 

        # Restore EAP (We want to do this ASAP)
        $ErrorActionPreference = $StoredEAP

        $Result.Online = $True

        if ($Lines.Count -gt 1) {
            $Headers = $Lines[0]
            $DataPositions = @($Headers.IndexOf("USERNAME"), $Headers.IndexOf("SESSIONNAME"), $Headers.IndexOf("ID"), 
                                $Headers.IndexOf("STATE"), $Headers.IndexOf("IDLE TIME"), $Headers.IndexOf("LOGON TIME"))

            for ($i=1; $i -lt $Lines.Count; $i++) {
                $UserData = $Lines[$i]
                $Result.Users += @{ Username=$UserData.Substring($DataPositions[0], $DataPositions[1]-$DataPositions[0]).Trim();
                                    SessionName=$UserData.Substring($DataPositions[1], $DataPositions[2]-$DataPositions[1]).Trim();
                                    Id=$UserData.Substring($DataPositions[2], $DataPositions[3] - $DataPositions[2]).Trim();
                                    State=$UserData.Substring($DataPositions[3], $DataPositions[4]-$DataPositions[3]).Trim();
                                    IdleTime=$UserData.Substring($DataPositions[4], $DataPositions[5]-$DataPositions[4]).Trim();
                                    LogonTime=$UserData.Substring($DataPositions[5], $UserData.Length - $DataPositions[5]).Trim() }
            }
        }
    } catch {
        #Write-Host "Server unavailable: $($_.Exception)"
        # Restore EAP incase of Exception
        $ErrorActionPreference = $StoredEAP

        # The (only?) exception where Server *is* online
        if ($_.Exception -like "*No User*") {
            $Result.Online = $True
        }
    }

    # Wait for the Ping Job to finish
    $PingResults = Receive-Job $PingJob -Wait
        
    # Unsure of all Job states, for now it's completed or a failure!
    # Remove the job, and check it's state simultaneously :O
    if ($PingJob.State -eq "Completed") {
        # Set the Ping data
        $Result.Ping.Pings = $PingResults

        # Pinging is a "success" if atleast 1 Ping was successful
        $Result.Ping.Success = ($PingResults | Where-Object { $_.Success }).Count -ge 1
    }

    # Remove da job !
    # I swear one time it returned a job object, and even though after vigorous testing it hasn't 
    # done it again, I am still piping this to null. No chances.
    Remove-Job $PingJob > $null

    return $Result
}