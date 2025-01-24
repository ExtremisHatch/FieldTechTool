# Contributors: Shaw, Ben | Taylor, Koupa | Farmer, Brandon

# - This script was designed to configure a user's computer for USB access as needed as Admin. Group Policy will remove USB access for users as usual, 
# but if the USB device remains in the machine, access is persistent until either the PC is restarted or USB device removed. 
# - If the user wishes to enable USB storage again (with existing approval), this app/script needs to be run again for an as-needed Just-in-Time 
# restoration of USB access.
# - All users that have been approved for USB storage access should be able to see this application in the software center. 

# Borrowing a C# form
Add-Type -AssemblyName System.Windows.Forms

# Explorer auto-restarts if killed, utilize that for restart functionality
function Restart-Explorer {
    # Restarting explorer by Taylor, Koupa
    # Aw shucks, thanks for the credit :)
    Get-Process -name explorer | ForEach-Object { $_.Kill() }
}

<# Returns the Following (Example):
Name                           Value                                                                                                                                             
----                           -----                                                                                                                                             
Write                          False                                                                                                                                             
Read                           False                                                                                                                                             
Execute                        False
#>
function GetUSBPermissions {
    param([Microsoft.Win32.RegistryKey]$USBRegistry)

    # Setup 'Parent' form to allow for 'TopMost' Property (AlwaysOnTop)
    $AlwaysOnTopForm = New-Object -TypeName System.Windows.Forms.Form -Property @{TopMost=$true}
    
    # Check if User already has full USB permissions
    $HasUSBPermissions = ($RegPath.Property | Where-Object { $RegPath.GetValue($_) -eq 0 }).Count -eq 3

    $USBPermissions = @{}

    # Permission Types, if '-eq 0' it means NOT deny meaning YES permission
    @('Read','Write','Execute') | % { $USBPermissions[$_] = ($RegPath.GetValue("Deny_$($_)") -eq 0) }

    return $USBPermissions
}

function SetUSBPermissions {
    param([Microsoft.Win32.RegistryKey]$USBRegistry, [hashtable]$Permissions)

    $Policy = "registry::"+ $USBRegistry.Name 
    
    # Filter through to ensure the permissions we're setting exists
    # Then set ItemProperty with opposite of value (Turn True into False, and vice versa, as the Value is for DENY not ALLOW)
    $Permissions.Keys | Where-Object { $ExistingValue = $USBRegistry.GetValue("Deny_$($_)"); return $ExistingValue -ne $null } | 
        % { Set-ItemProperty -Path $Policy -Name "Deny_$($_)" -Value ([int](-not $Permissions.Item($_))) }
}

function TestCanModifyRegistry {
    param([Microsoft.Win32.RegistryKey]$Registry)

    # Generate a random GUID so we know we aren't accidentally modifying existing value
    $TestValue = (New-Guid).ToString().Replace('-','')
    $Policy = "registry::"+ $Registry.Name 
    
    try {
        New-ItemProperty -Path $Policy -Name $TestValue -Value "0" > $null -ErrorAction Stop
        Remove-ItemProperty -Path $Policy -Name $TestValue > $null -ErrorAction Stop
    } catch {
        return $false
    }

    return $true
}

function Enable_USB {
    
    # Get Account, and UserSID, to create Regedit Path for RemoveableStorageDevices
    $Account = [System.Security.Principal.NTAccount] (Get-WMIObject -class Win32_ComputerSystem).Username
    $UserSID = $Account.Translate([System.Security.Principal.SecurityIdentifier]).Value 
    $RegPath = Get-ChildItem -Path ("registry::HKEY_USERS\$UserSID\Software\Policies\Microsoft\Windows\RemovableStorageDevices\")

    # Get Current USB Permissions/Capabilities
    $CurrentPermissions = GetUSBPermissions -USBRegistry $RegPath

    [PowerIO]::DisplayText("&[white;darkgray]Current USB Permissions:")
    $CurrentPermissions.Keys | % { $HasPerm = $CurrentPermissions.Item($_); [PowerIO]::DisplayText("`t&[gray]$($_): &[$(if ($HasPerm) {'green'} else {'red'})]$HasPerm") }

    # Create Parent form for TopMost setting by Taylor, Koupa
    $DisplayTopMost = New-Object System.Windows.Forms.Form -Property @{TopMost=$true}

    # User already has full USB Permissions
    if (-not $CurrentPermissions.ContainsValue($false)) {
        [System.Windows.Forms.MessageBox]::Show($DisplayTopMost,'USB (Storage) is already enabled!', 'Error!') > $null
        return
    }

    # Test if user has permissions to change Regedit values
    if (-not (TestCanModifyRegistry -Registry $RegPath)) {
        [System.Windows.Forms.MessageBox]::Show($DisplayTopMost,'You do not have permissions to change USB (Storage) regedit values! Try again with Administrator privileges.', 'Error!') > $null
        return
    }

    # Create a message box
    $result = [System.Windows.Forms.MessageBox]::Show($DisplayTopMost, 'USB (Storage) enablement will require a restart of Windows Explorer and close File explorer. This may cause some items on your screen to move or refresh.', 'Continue?', [System.Windows.Forms.MessageBoxButtons]::YesNo)

    # Check the result
    if ($result -eq [System.Windows.Forms.DialogResult]::No) {
        [System.Windows.Forms.MessageBox]::Show($DisplayTopMost,'You chose to not have USB (Storage) enabled.', 'Not needed') > $null
        return
    }

    # Permissions we'll change
    $PermissionsToChange = @{}

    # Filter down to just the permissions we still need, if not all
    $CurrentPermissions.Keys | Where-Object { $CurrentPermissions.Item($_) -ne $true } | % { $PermissionsToChange[$_] = $true }

    # Set Permissions
    SetUSBPermissions -USBRegistry $RegPath -Permissions $PermissionsToChange
    
    # Restart explorer for changes to take effect
    Restart-Explorer
    
    # Notify user of success
    [System.Windows.Forms.MessageBox]::Show($DisplayTopMost,'USB (Storage) enabled.', 'Success') > $null
}   
