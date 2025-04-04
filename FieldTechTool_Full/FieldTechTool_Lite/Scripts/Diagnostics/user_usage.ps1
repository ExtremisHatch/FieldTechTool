function IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function GetLastDesktopAccess {
    $UserData = @()
    $Users = Get-ChildItem -Path "C:\Users\" -Directory | Where-Object { $_.BaseName -ne 'Public' }

    $FailResult = if (IsAdmin) { $null } else { 'N/A (May need Admin permissions)' }
    
    # Both of these directories don't seem to randomly update
    # Seeing as both of these are pretty actively used when a user is logged in,
    # they should make for a good rough estimate of a Users last activity
    $Locations = @("C:\Users\{0}\AppData\Roaming\Microsoft\Windows\Recent",
                   "C:\Users\{0}\AppData\Local\Temp",
                   "C:\Users\{0}\AppData\Local\Microsoft\Windows\History\History.IE5")

    foreach ($User in $Users) {
        $Username = $User.BaseName

        $LastAccessed = $null

        $Locations | % {
            $Location = [String]::Format($_, $Username)
            if (Test-Path $Location -ErrorAction SilentlyContinue) {
                $File = Get-Item $Location
                if (($LastAccessed -eq $null) -or ($LastAccessed.LastWriteTime -lt $File.LastWriteTime)) {
                    $LastAccessed = $File
                }
            }
        }

        # A little messy, but easier to just toss 'if' statement in here
        $UserData += [PSCustomObject]@{UserName=$Username;
                                       LastAccess=$(if ($LastAccessed -eq $null) {$FailResult} else {$LastAccessed.LastWriteTime});}
    }

    $UserData = $UserData | Sort-Object -Property LastAccess -Descending

    $ExportData = @()
    $UserData | % { if ($_.LastAccess -ne $null -and $_.LastAccess.GetType() -eq [DateTime]) { $ExportData += [PSCustomObject]@{UserName=$_.UserName;LastAccess=$_.LastAccess.ToString("hh:mm:ss tt dd/MM/yyyy")}} else {$ExportData+=$_} } 
    $ExportData | ConvertTo-Html -As List | Out-File ".\Results\$($env:COMPUTERNAME)-LastDesktopAccess.htm"

    return $UserData
}

# Utilize a function to find the file
# By using '-Recurse' on GetChildItem we end up loading ALL files THEN checking for newer ones
# It is more performant to check one directory at a time, thus allowing to finish 'early'
function FindFileNewerThan {
    param([Parameter(Mandatory=$True)] $Path,
          [Parameter(Mandatory=$True)][DateTime] $Date,
          [boolean]$Recurse=$True)
    
    # Iterate over all Files, checking their Modified Date and their children files (if applicable)
    foreach ($File in (Get-ChildItem $Path -ErrorAction SilentlyContinue)) {
        
        # Return File if it's been modified since the Date provided
        if ($File.LastWriteTime -gt $Date) {
            return $File

        # Else if the File is also a Folder, rerun this function on the Folder
        } elseif ($Recurse -and $File.PSIsContainer) {
            $result = FindFileNewerThan -Path $File.FullName -Date $Date
            if ($result -ne $null) {
                return $result;
            }
        }
    }

    # Return $null to keep our Returns consistent
    return $null
}

# Potential flaw of this function is if we're running it and we're connected
# to the machine, aren't we inadvertently modifying files thus ruining these results?
# TODO: Potentially rename this method? It's not the 'Last' usage, just *any*
function GetLastDriveUsage {
    param([Parameter(Mandatory=$True)][DateTime]$SinceDate)

    # DriveType value of 4 = Network Drive (Not local to user)
    # AKA Filter down to local drives only (USBs, SSDs, C Drive)
    $LocalDrives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType.value__ -ne 4 }
    
    # Time Logging
    $StartTime = [DateTime]::Now
    
    # Store the potential file in a variable
    $File = FindFileNewerThan -Path $LocalDrives.RootDirectory -Date $SinceDate
    $LastUsage = if ($File -eq $null) { $null } else { $File.LastWriteTime }

    # Log the finished time
    $FinishTime = [DateTime]::Now
    $Difference = $FinishTime.Subtract($StartTime)
    
    $UsageData = @{LastUsage=$LastUsage;File=$File;TimeElapsed=$Difference}

    # This was a pain in my bottom, debugging why ConvertTo-Html doesn't like 99% of formats I give it (facepalm)
    [pscustomobject]@{"File Used At"="$($LastUsage.ToShortTimeString()) $($LastUsage.ToString("dd/MM/yyyy"))";
                      "File"=$($File.FullName);
                      "Time Elapsed Searching"="$($Difference.TotalMilliseconds) ms"} | ConvertTo-Html -As List | Out-File ".\Results\$($env:COMPUTERNAME)-LastDriveUsage.htm"
    
    return $UsageData
}