# As the script stands at the moment, this function is not needed but keeping in case 
# it's needed at a later time. 

function Prep-WASP {
    $moduleName = "WASP"
    $moduleInstalled = Get-Module -ListAvailable -Name $moduleName

    if ($moduleInstalled) {
        Write-Host "Module '$moduleName' is already installed." -ForegroundColor Green
    } else {
        Write-Host "Module '$moduleName' is not installed. Installing now..." -ForegroundColor Green
        Install-Module -Name $moduleName -Force
    }

    Import-Module -Name $moduleName
    
}
