

function Test-TermBackups {
    # Creating a hash table of known backup folders
    $mappingOptions = @{
        "AUA"= "\\briitnas01\backups"
        #"Germany" = "\\placeholderNas\backups"
    }
    # Prompt the user to select a mapping option or enter a custom one
    Write-Host "Select a mapping option or enter a custom network path:"
    foreach ($option in $mappingOptions.GetEnumerator()) {
        Write-Host "[$($option.Key)]: $($option.Value)"
    }
    $selectedOption = Read-Host "Enter your choice or a valid custom path."

    # Check if the user selected a predefined option or entered a custom path
    $networkDriveName = $mappingOptions[$selectedOption]
    if (-not $networkDriveName) {
        $networkDriveName = $selectedOption
    }

    Write-Host "If the network drive, $networkDriveName, is reachable, this application will automatically connect."
    Start-Sleep -Seconds 2
        
    if (Test-Path $networkDriveName) {
        Write-Host "$networkDriveName is accessible"
        Start-Sleep -Seconds 1.5
        Push-Location -Path $networkDriveName
        Clear-Host
        return $true
        
    } else {
        Write-Host "$networkDriveName is not accessible" -ForegroundColor Red
        Write-Host "Please check the name of $networkDriveName, make sure that you can access it with SA credentials, and try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Clear-Host
        break
    }

}

function Get-TargetDetails {
    if (Test-TermBackups) {
        # After successful mount, Read-Host for backup target's surname and firstname as Surname, Firstname
        # Using string formatting to ENSURE the formatting of Surname, Firstname 
        $surname = (Get-Culture).TextInfo.ToTitleCase((Read-Host "Please give the target's surname (Ex: Lastname): ").ToLower())
        $firstname = (Get-Culture).TextInfo.ToTitleCase((Read-Host "Please give the target's first name (Ex: Firstname): ").ToLower())
        
        # Read-Host user's folder to backup from the C:\Users
        $userFolder = Read-Host "Please give the target's home folder from C:\Users Ex: abcd12345 (case-insensitive): "
        $targetFolder = "C:\Users\$userFolder"

        # Making folder for termination backups
        $directoryPath = ".\$surname, $firstname"
        try {
            # If the directory doesn't exist, create it
            if (-not (Test-Path $directoryPath)) {
                New-Item -Path $directoryPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            }
            Write-Host "Directory should have been created"
            # Need second variable to test target folder. Otherwise, a "True " is pushed to the front of the string value.
            $folderExists = Test-Path $targetFolder
            if ($folderExists) {
                Write-Host "This is the current target: $targetFolder and the result of the test is $folderExists"
            }
            else {
                Write-Host "This is the current target: $targetFolder and the result of the test is $folderExists"
            }
            Set-Location $directoryPath
            Write-Host "Should be in the directory and ready to go" -ForegroundColor Green
            Start-Sleep -Seconds 2
            Clear-Host
            return $targetFolder
        }
        catch {
            Write-Host "Something went wrong testing access to the user folder. You'll have to start over" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            Clear-Host
            break
        }
    }
    else {
        Write-Host "Something went wrong in the mapping. Returning to Menu." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Clear-Host
        break
    }
    
}



function Invoke-RoboCopy {
    # Run robocopy as written in the original bat script with given variables
    $num_log_proc = (Get-WmiObject Win32_Processor | Select-Object NumberOfLogicalProcessors).NumberOfLogicalProcessors
    if (($num_log_proc * 10) -lt 129){
        # Depending on the computer, we can speed up default Multithreading of 8 threads. Creating a predictable value based on hardware.
        $MT_Value = ($num_log_proc * 10)
    }
    else {
        # highest value you can supply to MultiThreaded option. 
        $MT_Value = 128
    }
    $targetFolder = Get-TargetDetails
    robocopy.exe "$targetFolder" ".\" /TEE /R:0 /W:0 /XJ /E /MT:$MT_Value /XD "$targetFolder\AppData" "$targetFolder\OneDrive - Hatch Ltd" "$targetFolder\OneDrive" "$targetFolder\Hatch Ltd" "$targetFolder\Hatch EIM" "$targetFolder\Email" "$targetFolder\OneDrive" "$targetFolder\Hatch Ltd"
    Robocopy.exe "$targetFolder\AppData\Local\Microsoft\Outlook" ".\Local" /TEE /R:0 /W:0 /XJ /E /MT:$MT_Value /XD "$targetFolder\AppData" "$targetFolder\OneDrive - Hatch Ltd" "$targetFolder\OneDrive" "$targetFolder\Hatch Ltd" "$targetFolder\Hatch EIM" "$targetFolder\Email" "$targetFolder\OneDrive" "$targetFolder\Hatch Ltd"
    Write-Host "Backup completed. Returning to script menu." -ForegroundColor Green
    Start-Sleep -Seconds 3
}