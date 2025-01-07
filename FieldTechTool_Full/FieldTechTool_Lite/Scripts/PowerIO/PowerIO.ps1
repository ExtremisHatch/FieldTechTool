<#
    
        PowerIO Utility by Koupa
   
 Adds Powerful Input & Output Functionality

#>

# Include our TextTools for Output
. "$PSScriptRoot\PowerIOUtils\TextTools.ps1"
# Include InputTools for User Input
. "$PSScriptRoot\PowerIOUtils\InputTools.ps1"

class PowerIO {
    
    static [void] DisplayText([System.Object]$Text, [Boolean]$Newline) {
        HandleTextTypesOutput -Text $Text -NoNewline:(-not $Newline)
    }

    static [void] DisplayText([System.Object]$Text) {
        [PowerIO]::DisplayText($Text, $True)
    }

    static [String] ReadText([System.Object]$Text) {
        if ($Text -ne $null) { Write-Host -Object $Text -NoNewline }
        return $Global:Host.UI.ReadLine();
    }

    static [String] ReadText() {
        return [PowerIO]::ReadText($null);
    }

}

class PerfTracker {

    $times = [ordered]@{}

    PerfTracker() {

    }

    Start($Name) {
        $this.times[$Name] = @{StartTime=$null;EndTime=$null;}
        $this.times[$Name].StartTime = [DateTime]::Now
    }

    Stop($Name) {
        $StopTime = [DateTime]::Now
        $this.times[$Name].EndTime = $StopTime
    }

    [double] Duration($Name) {
        $Timings = $this.times[$Name]
        
        return ([DateTime]$Timings.EndTime).Subtract($Timings.StartTime).TotalMilliseconds
    }

    ListTiming($Name) {
        $Timings = $this.times[$Name]
        Write-Host "'$($Name)' Timings:"
        Write-Host " - Started: $($Timings.StartTime.ToString('h:MM:ss tt'))"
        Write-Host " - Ended: $($Timings.EndTime.ToString('h:MM:ss tt'))"
        Write-Host " - Duration: $($this.Duration($Name)) ms"
    }

    ListTimings() {
        $TotalDuration = 0
        $this.times.Keys | % {
            $this.ListTiming($_)
            $TotalDuration += $this.Duration($_)
        }
        
        Write-Host "Total: $($TotalDuration)ms"
    }
}