# function to simulate user
function Initialize-Interaction {
    param (
        [string] $test_file
    )
    
    # Next we'll simulate the user writing the Hatch Manifesto using notepad repeatedly. 
    try {
        # May need to implement logic similar to below to make sure that it opens and loads before
        # continuing. 
        Write-Edge
        $notepad = Start-Process notepad.exe $test_file -PassThru -WindowStyle Normal
        $wshell = New-Object -ComObject wscript.shell
        # Waiting for notepad to load and activate, then continue.
        while (-not $wshell.AppActivate($notepad.Id)) {
            Start-Sleep -Milliseconds 200
        }
        Write-Manifesto
        # Write-Host "You have 5 seconds to click here and Control+C to quit the script." -ForegroundColor Yellow
        Write-Host "Giving this 'user' time to write the manifesto" -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        Clear-Host
        Stop-Process -Id $notepad.Id
    }
    catch {
        Write-Host "Something went wrong."
        break
    }
}


# function to create sample_file if not exists
function Set-Sample_file {
    param (
        [string] $test_file
    )    
    if (!(Test-Path -Path $test_file)){
        Write-Host "File not created. Creating now." -ForegroundColor Cyan
        New-Item -ItemType File -Path $test_file
    }
}

# function to write our manifesto
function Write-Manifesto {
    # Using this article for inspiration with keys: https://admhelp.microfocus.com/uft/en/all/VBScript/Content/html/4b032417-ebda-4d30-88a4-2b56c24affdd.htm
    $wshell.SendKeys('^(+{END})')
    $wshell.SendKeys('{END}')
    $wshell.SendKeys('Our values: {ENTER}')
    $wshell.SendKeys('Doing our homework. {ENTER}')
    $wshell.SendKeys('Innovating all that we do. {ENTER}')
    $wshell.SendKeys('Acting like Owners. {ENTER}')
    $wshell.SendKeys('Encouraging a flat, connected organization. {ENTER}')
    $wshell.SendKeys('Engaging great people who make a difference. {ENTER}')
    $wshell.SendKeys('Thinking globally, acting locally. {ENTER}')
    $wshell.SendKeys('Achieving no harm. {ENTER}')
    $wshell.SendKeys('Ensuring cost effective, efficient delivery. {ENTER}')
    $wshell.SendKeys('Being unconditionally honest. {ENTER}')
    $wshell.SendKeys('Nurturing long-term relationships. {ENTER}')
    $wshell.SendKeys('Living our commitments with integrity. {ENTER}')
    $wshell.SendKeys('{ENTER}')
    $wshell.SendKeys('Our motto: {ENTER}')
    $wshell.SendKeys('We believe in exceptional ideas delivered with exceptional service. {ENTER}')
    $wshell.SendKeys('{ENTER}')
    $wshell.SendKeys('^s')
    
}

function Write-Edge {
    # Opening web browser and a simple search (working)
    Start-Process msedge.exe 'https://www.bing.com/search?q=Hatch' -WindowStyle Normal
    Start-Sleep -Seconds 4 # starting with 4 seconds during development
    Stop-Process -Name msedge -Force
}