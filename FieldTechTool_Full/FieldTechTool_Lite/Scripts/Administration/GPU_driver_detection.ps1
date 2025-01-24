# Function to get a List of all GPU Driver Configurations
# Essentially, a list of all GPU's and OS configurations
function GetNvidiaGPUList {
    # Have fun loading this in your browser lol
    $NvidiaGPUListURL = "https://gfwsl.geforce.com/nvidia_web_services/controller.php?com.nvidia.services.Drivers.getMenuArrayProductOperatingSystemMetaData/"
    
    # GET Request, No UserAgent supplied - Hasn't been blocked (yet)
    $Request = Invoke-WebRequest -Uri $NvidiaGPUListURL -DisableKeepAlive -Method Get

    # Turn that sweet sweet data into a useable object instead of 20+ MB of text lol
    $JsonData = $Request.Content | ConvertFrom-Json
   
    # Dispose request (cleanup)
    $Request.Dispose()
    
    # JsonObject containing all Product Names (Indexed, and also includes "MethodCalled" member)
    $ProductNames = $JsonData.ProductNames

    # Remove irrelevant property (Should be left with only Number indexes)
    $ProductNames.PSObject.Properties.Remove("MethodCalled")
    
    # Convert JsonObject into list of objects
    $GPUList = $ProductNames.PSObject.Properties.Value

    # Woop woop here comes the GPU list
    return $GPUList
}

# To hone in on the driver we want, we need to get current device data
# We also need to manipulate it, because OF COURSE NVidia has no standards
# (this might get a bit iffy)
function GetDriverDeviceInformation {
    # Convert "Microsoft Windows 11 Enterprise" -> "Windows 11"
    # Let's hope no one is running XP, or any other Win ver that isn't Windows XX (number number), otherwise womp womp
    $WindowsVersion = ((Get-WmiObject -class Win32_OperatingSystem).Caption | Select-String -Pattern "(Windows \d\d)").Matches[0].Value
    
    # '64-bit' or '32-bit' (Not relevant if using Windows 11 (Or 95, 98, 2000, NT4, ME, Linux, etc)
    $OSArchitecture = (Get-WmiObject win32_operatingsystem | select osarchitecture).osarchitecture
    
    # Device Type (Laptop or Desktop) https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystem
    # Unused, uncertain if Laptops require NVidia "Notebooks" drivers or not
    $IsLaptop = (Get-CimInstance -Class Win32_ComputerSystem -Property PCSystemType).PCSystemType -eq 2
    
    # https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
    # This is a list seemingly, so use 'contains'
    $IsNotebook = (Get-CimInstance -Class win32_systemenclosure).ChassisTypes -contains 10

    # Raw GPU Name, to be split for relevant info
    # Example of each step provided
    # GPUName "NVIDIA GeForce RTX 2070 with Max-Q Design"
    $GPU = Get-WmiObject Win32_VideoController | Where-Object Name -Like '*NVIDIA*'
    $GPUName = $GPU.Name
    
    # Split the name up for sectioning
    $GPUNameTokens = $GPUName.Split(' ')

    # "NVIDIA"
    $GPUBrand = $GPUNameTokens[0]
    
    # Temporary (?) Offset system to fix issues with GPU's not containing "GeForce"
    # Example from Brandon Test Laptop: "NVIDIA RTX A2000 8GB Laptop GPU"
    $PartOffset = if ($GPUName -notlike '*GeForce*') { -1 } else { 0 }

    # "GeForce"
    $GPUProductType = $GPUNameTokens[$PartOffset+1]
    
    # "RTX 2070 with Max-Q Design"
    $GPUProductSeries = $GPUNameTokens[($PartOffset+2)..($GPUNameTokens.Count - 1)] -join ' '

    # "RTX 2070"
    $ShortGPUName = $GPUNameTokens[($PartOffset+2)..($PartOffset+3)] -join ' '

    # Unused, as this value format doesn't really come up anywhere in Nvidia's API
    # Derive the 'proper' (hopefully) version number from this
    $GPUDriverVersion = $GPU.DriverVersion

    # My Computer reports the Driver Version as "32.0.15.5612"
    # Nvidia Control Panel states the version is "556.12"
    # I'm going out on a limb here and saying they're deriving it like the below
    # (What're the chances this is just a big coinky dink)
    $GPUShortDriverVersion = $GPUDriverVersion.Replace(".","") | % { $_.Substring($_.Length - 5).Insert(3, ".") }

    return @{WindowsVersion=$WindowsVersion;
             OSArchitecture=$OSArchitecture;
             IsLaptop=$IsLaptop;
             IsNotebook=$IsNotebook;
             GPUName=$GPUName;
             GPUBrand=$GPUBrand;
             GPUProductType=$GPUProductType;
             GPUProductSeries=$GPUProductSeries;
             ShortGPUName=$ShortGPUName;
             ShortGPUDriverVersion=$GPUShortDriverVersion}
}

# Unsure if I should pass data to this function, or if it should fetch it itself
# For convenience sake, I'll do the latter (for now)
# This function will find the closest match(es), and leave it up to the user to confirm
function FindRelevantGPUDrivers {
    param([switch] $OutputProgress)

    if ($OutputProgress) {
        [PowerIO]::DisplayText("&[white;darkgray]GPU Driver Check")
        [PowerIO]::DisplayText("`t&[gray]Gathering local device data...")
    }
    $Device = GetDriverDeviceInformation
    
    if ($OutputProgress) {
        [PowerIO]::DisplayText("`t&[gray]Loading NVidia GPU Configurations...")
    }

    $GPUList = GetNvidiaGPUList

    # Initial Filter to relevant OS results (Example: "Windows 11", "Windows 10 32-bit")
    $OSFilter = if ($Device.WindowsVersion.EndsWith('11')) { $Device.WindowsVersion } else { "$($Device.WindowsVersion) $($Device.OSArchitecture)" }

    if ($OutputProgress) {
        [PowerIO]::DisplayText("`t&[gray]Filtering through $($GPUList.Count) configuration(s)...")
    }

    $GPUDriverResults = @()

    :GPUIterator
    foreach ($GPUConfig in $GPUList) {
        # Product Name Example: GeForce RTX 20 Series (Notebooks) | GeForce RTX 2070 | Windows 11
        $ProductName = $GPUConfig.ProductNameMeta
        
        # Can't do nada if its null
        if ($ProductName -eq $null) {
            continue
        }
        
        # Check the Product Name contains most pieces of our data (GPU Names vary, such as "MaxQ Design" nonsense. Ignore that and only check important stuff)
        if (-not ($ProductName.EndsWith($OSFilter) -and ($ProductName -like "*$($Device.GPUProductType)*") -and ($ProductName -like "*$($Device.ShortGPUName)*"))) {
            continue
        }
    
        # The below isn't implemented yet, as I am unsure how correct the local Notebook classification is
        # Would rather include more results than filter out a correct result
        ## If we ARE a Notebook, look for a Notebook driver
        #if ($IsNotebook -and (-not $ProductName -like "*Notebook*")) {
        #    continue;
        #}
    
        # After confirming OUR data matches GPU Data
        # Confirm that GPU Data matches OUR data
        # Example: ProductNameMeta=GeForce RTX 20 Series | GeForce RTX 2070 SUPER | Windows 11
        # RTX 2070 will match RTX 2070 Super, but 2070 Super won't match RTX 2070
        $DataGPUName = $ProductName.Split('|')[1].Trim()
        
        foreach ($GPUPiece in $DataGPUName.Split(' ')) {
            if (-not ($Device.GPUName.Contains($GPUPiece))) {
               continue GPUIterator # Continue the outer loop
            }
        }

        # If we get this far, the match is pretty good
        # Store the driver data, and fetch the download URL
        $psid = $GPUConfig.ProductSeriesID
        $pfid = $GPUConfig.ProductFamilyID
        $osid = $GPUConfig.OperatingSystemID
        $languageCode = 1033 # English? May not be required
        $dch = 1 # This is for the Game Ready drivers I believe? Without it the URL returns the studio drivers | EDIT: WRONG

        # No idea what CRD is, but for Studio drivers the property 'IsCRD' = 1
        # Adding 'upCRD=1' into our query returns *only* Studio drivers
        # 10/12/24: It seems for the A2000 (Non GeForce?) GPU's, the upCRD param causes nothing to return
        # I believe it is due to there being no "Game Ready" ones for this GPU? Hence no filter needed? It works without!
        $upCRD = [int]($Device.GPUName -like "*GeForce*") # Needs testing on more devices
        $NvidiaDriverQueryURL = "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$psid&pfid=$pfid&osID=$osid&languageCode=$languageCode&dch=$dch&upCRD=$upCRD"
        # https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&qnf=0&ctk=null&numberOfResults=1&dch=1

        # Based on the response JSon format, if $Response.Success -eq 1, then the below should work
        # $Response.IDS[0].downloadInfo.DownloadURL
    
        $Request = Invoke-WebRequest -Uri $NvidiaDriverQueryURL -Method Get -DisableKeepAlive
        $Response = $Request.Content | ConvertFrom-Json

        $DownloadInfo = $Response.IDS[0].downloadInfo
        
        # "The Driver DownloadID details found"
        #$DownloadMessage = $DownloadInfo.Messaging.MessageValue
        
        $DriverName = [System.Web.HttpUtility]::UrlDecode($DownloadInfo.Name)
        $DriverDownloadURL = $DownloadInfo.DownloadURL
        $DriverVersion = $DownloadInfo.Version
        $DownloadSize = $DownloadInfo.DownloadURLFileSize
        $DriverDetails = [PSCustomObject]@{DownloadURL=$DriverDownloadURL;
                           DriverName=$DriverName;
                           ProductName=$ProductName;
                           DownloadSize=$DownloadSize;
                           DriverVersion=$DriverVersion}

        $GPUDriverResults += $DriverDetails
    }

    if ($OutputProgress) {
        [PowerIO]::DisplayText("&[gray]`tFinished with $($GPUDriverResults.Count) Driver result(s)")
    }

    # Utilize 'Unary Operator' to ensure an Array is returned, even when there's only 1 Object
    return ,$GPUDriverResults
}

function ProvideUserGPUDriverOptions {
    # Find Drivers, enable progress output so user doesn't think everything broke
    # For some reason, if there's only 1 result it's getting recasted as a single object instead of a list
    # Fix this by redefining it as a list (Well, an array)
    # After some research, it's a PowerShell 'quirk'. This can be fixed with a Unary operator. (Keeping the type casting for future reference)
    $GPUDrivers = [System.Array] (FindRelevantGPUDrivers -OutputProgress)
    
    if ($GPUDrivers.Count -eq 0) {
        [PowerIO]::DisplayText("&[red]Couldn't find any Drivers online, this may be an error!")
    } else {
        [PowerIO]::DisplayText("&[gray]Found &[highlight]$($GPUDrivers.Count)&[gray] potential driver(s)!")
    
        $Device = GetDriverDeviceInformation
    
        # Current GPU Driver Version (Shortened NVidia "Standard" lol)
        $CurrentVersion = $Device.ShortGPUDriverVersion | % { @{Version=([double]$_);Major=([int]$_.Split('.')[0]);Minor=([int]$_.Split('.')[1])} }
        
        # Get the latest available version out of the results, then manipulate into a nice convenient object (Very clean, totally doesn't need a rewrite)
        $LatestAvailable = ($GPUDrivers.DriverVersion | %{[double]$_} | Sort-Object -Descending | Select-Object -First 1) | `
                            % { @{Version=$_;Major=([int]$_.ToString().Split('.')[0]);Minor=([int]$_.ToString().Split('.')[1])} }
        
        $Outdated = $LatestAvailable.Version -gt $CurrentVersion.Version
        $OutdatedType = if ($Outdated) { if ($LatestAvailable.Major -gt $CurrentVersion.Major) {"Major"} else {"Minor"} } else { $null }
    
        # List out current details for user
        [PowerIO]::DisplayText("`n&[yellow]Current GPU: &[highlight]$($Device.GPUName)")
    
        # If Outdated, don't print new line yet
        [PowerIO]::DisplayText("`t&[yellow]Driver Version: &[highlight]$($Device.ShortGPUDriverVersion)", -not $Outdated)
    
        if ($Outdated) {
            [PowerIO]::DisplayText(" &[gray][&[magenta]Potential &[highlight]$OutdatedType&[magenta] Update Available&[gray]]")
        }
    
        [PowerIO]::DisplayText("`n&[white;darkgray]Drivers Available:")
        for ($i=0; $i -lt $GPUDrivers.Count; $i++) {
            $Driver = $GPUDrivers[$i]
            [PowerIO]::DisplayText("[$($i+1)] &[yellow]$($Driver.ProductName)")
            [PowerIO]::DisplayText("`t$($Driver.DriverName) &[gray][Version: $($Driver.DriverVersion)]")
            [PowerIO]::DisplayText("`tDownload URL &[gray][$($Driver.DownloadSize)]&[]: $($Driver.DownloadURL)")
        }
    
        $DownloadDriver = @("Y","YES") -contains (QueryUser -AnswerRequired -Question "`n&[yellow]Would you like to download a listed GPU Driver? &[](&[green]Y&[]/&[red]n&[])" )
        if ($DownloadDriver) {
            while (($DriverIndex = QueryUser -AnswerRequired -Question "Please input the Number of the GPU Driver you wish to download") -ne $null) {
                # Ensure it's a number
                if ($DriverIndex -notmatch "^(\d)*$") { continue; }
                
                # Cast to Int
                $DriverIndex = [int]$DriverIndex;
    
                # If it's within range, break!
                if ($DriverIndex -le $GPUDrivers.Count -and $DriverIndex -gt 0) { break; }
            }
    
            # Driver Selected by User
            $SelectedDriver = $GPUDrivers[$DriverIndex-1]
            $DownloadURL = $SelectedDriver.DownloadURL
    
            # If DownloadURL ends with ".exe", ".app", ".XXX", we will keep the end of the URL as the file name
            $FileName = if ($DownloadURL -match "\.[a-zA-Z0-9]{2,3}$") { $DownloadURL.Substring($DownloadURL.LastIndexOf('/') + 1) } else {'GPU-Driver.exe'}
            
            # Local Output Path
            $OutputPath = ".\Drivers\"
            $DriverLocation = "$($OutputPath)$($FileName)"
            if (-not (Test-Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType "Directory" > $null
            }
    
            [PowerIO]::DisplayText("&[yellow]Downloading `"&[highlight]$($SelectedDriver.ProductName)&[yellow]`" driver &[gray][$($SelectedDriver.DownloadSize)]")
            [PowerIO]::DisplayText("`t&[gray]This may take some time...")
    
            Invoke-WebRequest -Uri $DownloadURL -OutFile $DriverLocation
    
            [PowerIO]::DisplayText("&[green]Download completed!")
            [PowerIO]::DisplayText("&[yellow]Driver Location: &[gray]$((Get-Item $DriverLocation).FullName)")
        }
    }
}