# This is a script that will simulate some usage on the target machine for the purposes
# of testing normal use after a repair or component replacement.

# Imports
. .\Scripts\Diagnostics\Helper_stuff\user_interation.ps1
$temp = Resolve-Path ".\Scripts\Diagnostics\Helper_stuff\run_forever.ps1"
$tempToString = "`"$temp`""
$keep_running = $tempToString

# Need to fix this. We'll need to make sure that the sample file is mapping correctly to the 
# variable and then pass it to the set-sample_file function to ensure that it's set properly. 
$sample_file = '.\Results\sample_file.txt'

function Start-Simulate_Usage {
    # From user_interation.ps1
    # Create a file and continuously write to the file. At the end of testing, we'll need to 
    # get this removed for cleanup. 
    Set-Sample_file -test_file $sample_file
    Initialize-Interaction -test_file $sample_file 
    # Giving user time to enter a response after running
    Start-Sleep -Seconds 3

}


function Invoke-SimulatorController {
    # $psi = New-Object System.Diagnostics.ProcessStartInfo
    # $psi.FileName = "powershell.exe $keep_running"
    # $psi.ArgumentList = "-File", $keep_running.ToString()
    # Write-Host "keep running is $keep_running and has the type of $keep_running.GetType()"
    # $process = [System.Diagnostics.Process]::Start($psi)
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-File $keep_running" -PassThru -WindowStyle Minimized
    
    Write-Host "Running a minimized powershell session for the simulator." -BackgroundColor Yellow
    Write-Host "We recommend you wait until notepad closes to enter a response. You'll have 3 seconds before the next cycle." -BackgroundColor Yellow
    $userResponse = Read-Host "Press y, then enter to close the session. If you mess up, it'll close anyway."
        
    switch ($userResponse.ToLower()) {
        'y' {
            $process.Kill()
            Write-Host "The session has been closed."
            Start-Sleep -Seconds 3
            Clear-Host
        }
        default {
            Write-Host "Invalid response, so closing anyway"
            $process.Kill()
            Start-Sleep -Seconds 3
            Clear-Host
        }
    }
}