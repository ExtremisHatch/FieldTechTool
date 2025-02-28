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

# Title Text for tool (Shown once, only on start)
$StyledTitle = [StyledText]::Create("&[red;highlight]FIELD`n     &[red;highlight]TECH`n         &[red;highlight]TOOL")

# Styles to apply to the title text
$Styles = @([BoxStyle]::Create([BoxStyle]::DOTTED, 'yellow;red', 0, ';red'), 
            [BoxStyle]::Create([BoxStyle]::DOTTED, 'red;yellow', 0),
            [CornerStyle]::Create([CornerStyle]::THIN, 'yellow'))

# Apply all those good ole styles, how stylish
$Styles | % { $StyledTitle.Style($_) > $null <# Pump output to null #> } 

# Display the Title Text, with an additional Newline for cleaner separation
$StyledTitle.Append("`n").Display()

# Main menu
Show-MainMenu
