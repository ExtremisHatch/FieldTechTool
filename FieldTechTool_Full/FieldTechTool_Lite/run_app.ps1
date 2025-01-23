# Author: Farmer, Brandon

# Purpose of this application is to compose an 'all-in-one' tool for techs to use common 
# troubleshooting applications in the field.

# Possible names:
# - FieldTech
# - FieldTechTool
# - FieldTechToolbox

# Set Location to Script File Location, as all Paths are relative
# This'll typically only affect users in Powershell ISE, whom haven't directly run the file (Such as myself, for development)
Set-Location $PSScriptRoot

# Imports
Import-Module -Force "$PSScriptRoot\Scripts\PowerIO\PowerIO.psd1"
. .\Menus\main_menu.ps1

# Main menu
Show-MainMenu
