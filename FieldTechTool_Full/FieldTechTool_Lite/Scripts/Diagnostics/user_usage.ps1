function IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function GetLastDesktopAccess {
    $UserData = @()
    $Users = Get-ChildItem -Path "C:\Users\" -Directory | Where-Object { $_.BaseName -ne 'Public' }

    $FailResult = if (IsAdmin) { $null } else { 'N/A (May need Admin permissions)' }
    
    foreach ($User in $Users) {
        $Username = $User.BaseName
        $Desktop = "$($User.FullName)\Desktop"
        if (Test-Path $Desktop -ErrorAction SilentlyContinue) {
            $UserData += [PSCustomObject]@{UserName=$Username;LastAccess=(Get-Item $Desktop).LastAccessTime}
        } else {
            # If the User exists they should have a Desktop folder
            # However, you may not have permissions to view (or potentially it doesn't exist?)
            $UserData += [PSCustomObject]@{UserName=$Username;LastAccess=$FailResult}
        }
    }

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
        if ($File.LastWriteTime -lt $Date) {
            return $File

        # Else if the File is also a Folder, rerun this function on the Folder
        } elseif ($File.PSIsContainer) {
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
    
    return @{LastUsage=$LastUsage;File=$File;TimeElapsed=$Difference}
}