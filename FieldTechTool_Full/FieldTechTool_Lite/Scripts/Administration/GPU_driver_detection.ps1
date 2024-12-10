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
    $GPUName = Get-WmiObject Win32_VideoController | Where-Object Name -Like '*NVIDIA*' | % { $_.Name }
    
    # Split the name up for sectioning
    $GPUNameTokens = $GPUName.Split(' ')

    # "NVIDIA"
    $GPUBrand = $GPUNameTokens[0]
    
    # "GeForce"
    $GPUProductType = $GPUNameTokens[1]
    
    # "RTX 2070 with Max-Q Design"
    $GPUProductSeries = $GPUNameTokens[2..($GPUNameTokens.Count - 1)] -join ' '

    # "RTX 2070"
    $ShortGPUName = $GPUNameTokens[2..3] -join ' '

    return @{WindowsVersion=$WindowsVersion;
             OSArchitecture=$OSArchitecture;
             IsLaptop=$IsLaptop;
             IsNotebook=$IsNotebook;
             GPUName=$GPUName;
             GPUBrand=$GPUBrand;
             GPUProductType=$GPUProductType;
             GPUProductSeries=$GPUProductSeries;
             ShortGPUName=$ShortGPUName}
}

# Unsure if I should pass data to this function, or if it should fetch it itself
# For convenience sake, I'll do the latter (for now)
# This function will find the closest match(es), and leave it up to the user to confirm
function FindRelevantGPUDrivers {
    $Device = GetDriverDeviceInformation
    $GPUList = GetNvidiaGPUList

    # Initial Filter to relevant OS results (Example: "Windows 11", "Windows 10 32-bit")
    $OSFilter = if ($Device.WindowsVersion.EndsWith('11')) { $Device.WindowsVersion } else { "$($Device.WindowsVersion) $($Device.OSArchitecture)" }

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
               #Write-Host "'$GPUName' doesn't contain '$GPUPiece' [$DataGPUName]"
               continue GPUIterator # Continue the outer loop
            }
        }
        Write-Host "GPU DATA"
        Write-Host $GPUConfig
        Write-Host ""
        # If we get this far, the match is pretty good
        # Store the driver data, and fetch the download URL
        $psid = $GPUConfig.ProductSeriesID
        $pfid = $GPUConfig.ProductFamilyID
        $osid = $GPUConfig.OperatingSystemID
        $languageCode = 1033 # English? May not be required
        $dch = 0 #1=GameReady # This is for the Game Ready drivers I believe? Without it the URL returns the studio drivers

        # No idea was CRD is, but for Studio drivers the property 'IsCRD' = 1
        # Adding 'upCRD=1' into our query returns *only* Studio drivers
        
        $NvidiaDriverQueryURL = "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$psid&pfid=$pfid&osID=$osid&languageCode=$languageCode&dch=$dch&upCRD=1"
        Write-Host "Quering URL"
        Write-Host $NvidiaDriverQueryURL
        # Based on the response JSon format, if $Response.Success -eq 1, then the below should work
        # $Response.IDS[0].downloadInfo.DownloadURL
    
        $Request = Invoke-WebRequest -Uri $NvidiaDriverQueryURL -Method Get -DisableKeepAlive
        $Response = $Request.Content | ConvertFrom-Json
        $Response > "C:\Users\TAYL17691\Desktop\Code\output2.txt"
        $DownloadInfo = $Response.IDS[0].downloadInfo
        $DownloadMessage = $DownloadInfo.Messaging.MessageValue
        $DriverDownloadURL = $DownloadInfo.DownloadURL
    
        Write-Host "Driver Status: $DownloadMessage"
        Write-Host "Download URL (If Available): $DriverDownloadURL"
    }
}

