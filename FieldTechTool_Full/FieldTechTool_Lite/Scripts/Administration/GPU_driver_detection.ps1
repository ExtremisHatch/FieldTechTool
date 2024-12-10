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
             GPUproductSeries=$GPUProductSeries;
             ShortGPUName=$ShortGPUName}
}