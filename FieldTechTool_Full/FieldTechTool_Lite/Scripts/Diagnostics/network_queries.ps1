function QueryNetworkMachine {
    param($Server)

    $Result = @{Online=$False; Users=@()}

    $StoredEAP = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    try {
        $Lines = @(quser /server:$Server) 
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
    } 

    # Restore EAP
    $ErrorActionPreference = $StoredEAP
    return $Result
}