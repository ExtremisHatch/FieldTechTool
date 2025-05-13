# Primary contributor: Stock, Jack
# Assistant contributor: Farmer, Brandon

function Edit-MachineName {
    try {
        # Get the serial number of the computer
        $serialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber.Trim()

        # Get the current computer name
        $currentName = $env:COMPUTERNAME

        # Check if the current name is already the serial number
        if ($currentName -ne $serialNumber) {
            Write-Host "Renaming computer from '$currentName' to '$serialNumber' and will force a restart in 5 seconds"
            Start-Sleep -Seconds 5
            Rename-Computer -NewName $serialNumber -Force -Restart
        } else {
            Write-Host "Computer name is already set to the serial number: '$serialNumber'"
            Start-Sleep -Seconds 3
        }
    }
    catch {
        Write-Host "Something went wrong with our script unfortunately"
        Start-Sleep -Seconds 3
        Clear-Host
    }    
}