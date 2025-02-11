

function Test-TermBackups {
    # Creating a hash table of known backup folders
    $mappingOptions = @{
        "AUA"= "\\briitnas01\backups"
        #"Germany" = "\\placeholderNas\backups"
    }
    # Prompt the user to select a mapping option or enter a custom one
    [PowerIO]::DisplayText("&[yellow]Select a mapping option or enter a custom network path:")
    foreach ($option in $mappingOptions.GetEnumerator()) {
        [PowerIO]::DisplayText("&[gray][$($option.Key)]: &[yellow]$($option.Value)")
    }
    $selectedOption = QueryUser -AnswerRequired -Question "Enter your choice or a valid custom path."

    # Check if the user selected a predefined option or entered a custom path
    $networkDriveName = $mappingOptions[$selectedOption]
    if (-not $networkDriveName) {
        $networkDriveName = $selectedOption
    }

    [PowerIO]::DisplayText("If the network drive, &[highlight]$networkDriveName&[], is reachable, this application will automatically connect.")
    Start-Sleep -Seconds 2
        
    if (Test-Path $networkDriveName) {
        [PowerIO]::DisplayText("&[highlight]$networkDriveName&[] is &[green]accessible")
        Start-Sleep -Seconds 1.5
        Push-Location -Path $networkDriveName
        Clear-Host
        return $true
        
    } else {
        [PowerIO]::DisplayText("&[highlight]$networkDriveName&[] is &[red]not accessible")
        [PowerIO]::DisplayText("&[gray]Please check the name of &[highlight]$networkDriveName&[gray], make sure that you can access it with SA credentials, and try again.")
        Start-Sleep -Seconds 2.5
        Clear-Host
        break
    }

}

function Get-TargetDetails {
    if (Test-TermBackups) {
        # After successful mount, Read-Host for backup target's surname and firstname as Surname, Firstname
        # Using string formatting to ENSURE the formatting of Surname, Firstname 
        $surname = (Get-Culture).TextInfo.ToTitleCase((QueryUser -AnswerRequired -Question "&[gray]Please provide the target's surname (Ex: Lastname): ").ToLower())
        $firstname = (Get-Culture).TextInfo.ToTitleCase((QueryUser -AnswerRequired -Question "&[gray]Please provide the target's first name (Ex: Firstname): ").ToLower())
        
        # Read-Host user's folder to backup from the C:\Users
        $userFolder = QueryUser -AnswerRequired -Question "&[gray]Please provide the target's home folder from C:\Users Ex: abcd12345 (case-insensitive): "
        $targetFolder = "C:\Users\$userFolder"

        # Making folder for termination backups
        $directoryPath = ".\$surname, $firstname"
        try {
            # If the directory doesn't exist, create it
            if (-not (Test-Path $directoryPath)) {
                New-Item -Path $directoryPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            }
            [PowerIO]::DisplayText("&[gray]Directory should have been created")
            # Need second variable to test target folder. Otherwise, a "True " is pushed to the front of the string value.
            $folderExists = Test-Path $targetFolder
            
            [PowerIO]::DisplayText("&[gray]This is the current target: &[highlight]$targetFolder&[gray] and the result of the test is &[$(if($folderExists){"green"}else{"red"})]$folderExists")
            
            Set-Location $directoryPath
            [PowerIO]::DisplayText("&[green]Should be in the directory and ready to go")
            Start-Sleep -Seconds 2
            Clear-Host
            return $targetFolder
        }
        catch {
            [PowerIO]::DisplayText("&[yellow]Something went wrong testing access to the user folder. You'll have to start over")
            Start-Sleep -Seconds 2
            Clear-Host
            break
        }
    }
    else {
        [PowerIO]::DisplayText("&[red]Something went wrong in the mapping. Returning to Menu.")
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
    [PowerIO]::DisplayText("&[green]Backup &[highlight]completed&[green]. Returning to script menu.")
    Start-Sleep -Seconds 3
}