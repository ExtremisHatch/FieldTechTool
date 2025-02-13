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

    # Method for formatting ping color
    $FormatPing = {
        param([int] $Ping)
        if ($Ping -le 100) { return "&[green]${Ping}ms" } elseif ($Ping -le 250) { return "&[yellow]${Ping}ms" } else { return "&[red]${Ping}ms" }
    }

    # Method for formatting success rate %
    $FormatSuccessRate = {
        param([Hashtable]$PingCount)
        $Percentage = [double] ($PingCount.Success / $PingCount.Total)
        $Color = if ($Percentage -gt 0.9) { 'green' } elseif ($Percentage -gt 0.65) { 'yellow' } else { 'red' }
        return $Percentage.ToString("&[$Color]0%")
    }

    $FormatPingVariance = {
        param([double] $Variance, $Average)
        $Variance = $Variance/$Average
        $Color = if ($Variance -le 0.15) { 'green' } elseif ($Variance -le 0.35) { 'yellow' } else { 'red' }
        return $Variance.ToString("&[$Color]0%")
    }

    $PingResults = $Result.Ping
    $PingStatus = if ($PingResults.Success) { "&[green]Successful" } else { "&[red]Failed" }
    
    # Display the Ping Status
    [PowerIO]::DisplayText("`t&[gray]Ping: $PingStatus")

    # If Ping was successful, display ping stats
    if ($PingResults.Success) {
        $ResultsText = "Results: "
        $ResultOffset = "`t`t`t" # Fancy alignment
        [PowerIO]::DisplayText("`t`t&[gray]$ResultsText")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Success Rate: $($FormatSuccessRate.Invoke($PingResults.Count))&[gray] [$($PingResults.Count.Success)/$($PingResults.Count.Total)]")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Response Time: $($FormatPing.Invoke($PingResults.Average))&[gray] [Min: $($FormatPing.Invoke($PingResults.Minimum))&[gray], Max: $($FormatPing.Invoke($PingResults.Maximum))&[gray]]")
        [PowerIO]::DisplayText("${ResultOffset}&[gray]Variance: $($FormatPingVariance.Invoke($PingResults.Variance, $PingResults.Average))&[gray] [+- $($PingResults.Variance.ToString('0.0'))ms]")
    }

    #
    # Desktop/Server User List & Info
    #

    # Uncertain if $Result.Online = $false means no users will show, best just checking if there is users
    if ($Result.Users.Count -gt 0) {
        [PowerIO]::DisplayText("`t&[Gray]Users: &[green]$($Result.Users.Count)")

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

function QueryNetworkMachine {
    param($Server, $PingTimeout=2000, $PingCount=5)

    $Result = @{Online=$False; Users=@(); Ping=@{Success=$False;Minimum=-1;Maximum=-1;Average=-1;Variance=-1;Count=@{Total=$PingCount;Failed=-1;Success=-1}}}

    # Before we do anything, start the ping job in the background
    $PingJob = Start-Job -ScriptBlock {
        param($Server, $Timeout, $Count)
        $Pings = @() # List of pings
        for ($i = 0; $i -lt $Count; $i++) {
            $Ping = (Get-WmiObject -Class Win32_PingStatus -Filter ('Address="{0}" and Timeout={1}' -f $Server, $Timeout) | Select-Object ResponseTime, StatusCode)
            $Pings += @{Success=($Ping.StatusCode -eq 0);
                        ResponseTime=($Ping.ResponseTime);}
        }
        return $Pings
    } -ArgumentList $Server, $PingTimeout, $PingCount


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
    }




    # Unsure of all the states right now, looking for number states rather than Str Compare
    if ($PingJob.State -eq "Completed") {
        $PingResults = Receive-Job $PingJob -Wait -AutoRemoveJob
        
        # If all of our pings failed, then pinging failed!
        $SuccessfulPings = ($PingResults | Where-Object { $_.Success })
        $Failed = $SuccessfulPings.Count -eq 0

        $Result.Ping.Count.Success = $SuccessfulPings.Count 
        $Result.Ping.Count.Failed = $PingCount - $SuccessfulPings.Count

        if (-not $Failed) {
            $Result.Ping.Success = $True
            $Result.Ping.Average = [int] ($SuccessfulPings.ResponseTime | Measure-Object -Average).Average
            $Result.Ping.Minimum = [int] ($SuccessfulPings.ResponseTime | Measure-Object -Minimum).Minimum
            $Result.Ping.Maximum = [int] ($SuccessfulPings.ResponseTime | Measure-Object -Maximum).Maximum
            $Result.Ping.Variance = $Result.Ping.Average - $Result.Ping.Minimum
        }
    }

    return $Result
}