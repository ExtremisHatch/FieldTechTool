# Contributors: Shaw, Ben | Taylor, Koupa | Farmer, Brandon

# - This script was designed to configure a user's computer for USB access as needed as Admin. Group Policy will remove USB access for users as usual, 
# but if the USB device remains in the machine, access is persistent until either the PC is restarted or USB device removed. 
# - If the user wishes to enable USB storage again (with existing approval), this app/script needs to be run again for an as-needed Just-in-Time 
# restoration of USB access.
# - All users that have been approved for USB storage access should be able to see this application in the software center. 

# Borrowing a C# form
Add-Type -AssemblyName System.Windows.Forms

function Enable_USB {
    
    # Create Parent form for TopMost setting by Taylor, Koupa
    $DisplayTopMost = New-Object System.Windows.Forms.Form -Property @{TopMost=$true}

    # Create a message box
    $result = [System.Windows.Forms.MessageBox]::Show($DisplayTopMost, 'USB (Storage) enablement will require a restart of Windows Explorer and close File explorer. This may cause some items on your screen to move or refresh.', 'Continue?', [System.Windows.Forms.MessageBoxButtons]::YesNo)

    # Check the result
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $UserName = Get-WMIObject -class Win32_ComputerSystem | Select-Object username
        $UserSID = ([System.Security.Principal.NTAccount]($UserName.username)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $regpath= Get-ChildItem -Path ("registry::HKEY_USERS\"+$UserSID+"\Software\Policies\Microsoft\Windows\RemovableStorageDevices\")
        $Policy = "registry::"+ $regPath.Name 
        Set-ItemProperty $Policy -Name "DENY_Write" -Value "0"
        Set-ItemProperty $Policy -Name "DENY_Read" -Value "0"
        Set-ItemProperty $Policy -Name "DENY_Execute" -Value "0"

        # Restarting explorer by Taylor, Koupa
        Get-Process -name explorer | ForEach-Object { $_.Kill() }

        [System.Windows.Forms.MessageBox]::Show($DisplayTopMost,'USB (Storage) enabled.', 'Success')
    } 
    # A future refactor, I'll remove a lot of this duplication. Will make an issue for this. 
    else {
        [System.Windows.Forms.MessageBox]::Show($DisplayTopMost,'You chose to not have USB (Storage) enabled.', 'Not needed')
        $UserName = Get-WMIObject -class Win32_ComputerSystem | Select-Object username
        $UserSID = ([System.Security.Principal.NTAccount]($UserName.username)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $regpath= Get-ChildItem -Path ("registry::HKEY_USERS\"+$UserSID+"\Software\Policies\Microsoft\Windows\RemovableStorageDevices\")
        $Policy = "registry::"+ $regPath.Name 
        Set-ItemProperty $Policy -Name "DENY_Write" -Value "1"
        Set-ItemProperty $Policy -Name "DENY_Read" -Value "1"
        Set-ItemProperty $Policy -Name "DENY_Execute" -Value "1"

        # Restarting explorer by Taylor, Koupa
        Get-Process -name explorer | ForEach-Object { $_.Kill() }

        [System.Windows.Forms.MessageBox]::Show($DisplayTopMost,'USB (Storage) disabled.', 'Success')
    }
    
}   
