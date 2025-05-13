# Primary contributor: Stock, Jack
# Assistant contributor: Farmer, Brandon

function Get-JackInfo {
    Clear-Host
    # Capture the path for Results folder for updating CSV
    $path = Resolve-Path '.\Results\'
    # Start process
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    New-Item -Type Directory -Path "C:\HWID"
    Set-Location -Path "C:\HWID"
    $env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
    # Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
    Install-Script -Name Get-WindowsAutopilotInfo
    Set-Location -Path $path
    Get-WindowsAutopilotInfo -OutputFile 'AutopilotHWID.csv'
    Set-Location ../
    Clear-Host
    Write-Host "Output saved to FieldTechTool_Lite\Results folder. Please give this information to Jack Stock for further processing. Thank you!!" -ForegroundColor Cyan
    Start-Sleep -Seconds 4
}