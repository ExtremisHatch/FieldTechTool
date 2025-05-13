class PowerIO {
    # Table of Symbols
    static [HashTable] $Symbols = @{
        WARNING=([char]9888);
        LEFT_TRIANGLE=[TriangleSymbol]::Get('LEFT');
        RIGHT_TRIANGLE=[TriangleSymbol]::Get('RIGHT');
        DOWN_TRIANGLE=[TriangleSymbol]::Get('DOWN');
        UP_TRIANGLE=[TriangleSymbol]::Get('UP');
    }

    static [void] DisplayText([System.Object]$Text, [Boolean]$Newline) {
        HandleTextTypesOutput -Text $Text -NoNewline:(-not $Newline)
    }

    static [void] DisplayText([System.Object]$Text) {
        [PowerIO]::DisplayText($Text, $True)
    }

    static [String] ReadText([System.Object]$Text) {
        if ($Text -ne $null) { [PowerIO]::DisplayText($Text, $False) }
        return $Global:Host.UI.ReadLine();
    }

    static [String] ReadText() {
        return [PowerIO]::ReadText($null);
    }

    static DisplayError([Object] $TheError) {
        [String] $ErrorText = '';

        if ($TheError -is [System.Management.Automation.RuntimeException]) {
            $TheError = $TheError.ErrorRecord # Reassign TheError to the ErrorRecord
        }

        if ($TheError -is [System.Management.Automation.ErrorRecord]) {
            $TertiaryColor = "&[darkyellow;black]"
            $fields = $TheError.InvocationInfo.MyCommand.Name,
                      $TheError.ErrorDetails.Message,
                      $TheError.InvocationInfo.PositionMessage,
                      $TheError.CategoryInfo.ToString(),
                      $TheError.FullyQualifiedErrorId

                                    
            $Format = @()
            # If it's got details for it, add in InvocationInfo & ErrorDetails message
            if ($fields[0] -notlike $null -or $fields[1] -notlike $null) {
                $Format += "&[red]{0}: {1}"
            }

            if ($fields[2] -notlike $null) {
                # InvocationInfo.PositionMessage
                # At line:45 char:16
                # + ... <spaces> <code>
                # + <spaces> <underline>
                $PositionInfo = [TextTools]::GetLines($fields[2])

                # Remove prefix "+ <spaces>"
                $Offset = (Select-String -Pattern "[^ +.]" -InputObject $PositionInfo[1]).Matches[0].Index
                $PositionInfo[1] = $PositionInfo[1].Substring($Offset)
                $PositionInfo[2] = $PositionInfo[2].Substring($Offset)

                $Format += "$TertiaryColor + &[red]$($PositionInfo[0])"
                $Format += "$TertiaryColor + &[red;white]$($PositionInfo[1])"
                $Format += "$TertiaryColor + &[red]$($PositionInfo[2])"
            } else {
                $Format += "$TertiaryColor + &[red]Exception:&[yellow] $($TheError.Exception.Message)"
            }

            $Format +=  "$TertiaryColor + &[red]CategoryInfo:&[yellow] {3}"
            $Format +=  "$TertiaryColor + &[red]FullyQualifiedErrorId:&[yellow] {4}"

            $ErrorText = ($Format -join "`n" -f $fields)
        } else {
            $ErrorType = if ($TheError -eq $null) { 'null' } else { $TheError.GetType().name }
            $ErrorText = "&[red]Error (Unhandled Type: '$ErrorType')"
            if ($TheError -ne $null) { 
                $ErrorText += ":`n&[red]Error: &[yellow]'$TheError&[yellow]'"
            }
        }
        [PowerIO]::DisplayText($ErrorText)
    }
}

# Triangle Symbol Utility Class
class TriangleSymbol {
    hidden static $HOLLOW_OFFSET = 1
    hidden static $SMALL_OFFSET = 2
    hidden static $DIRECTIONS = @('LEFT','UP','RIGHT','DOWN')
    # https://unicodelookup.com/#triangle/1
    hidden static $DEFINITIONS = @{LEFT=9664;UP=9650;RIGHT=9654;DOWN=9660}

    hidden $Direction = @{Name='';Index=''}
    hidden $Effects = @{Hollow=$False; Small=$False}

    TriangleSymbol($Direction) {
        $this.Direction.Index = [TriangleSymbol]::DIRECTIONS.IndexOf($Direction.ToUpper())
        $this.Update()
    }

    [TriangleSymbol] Rotate($Value) {
        $this.Direction.Index = ($this.Direction.Index + $Value) % [TriangleSymbol]::DIRECTIONS.Count
        $this.Update()
        return $this
    }

    [TriangleSymbol] RotateRight() {
        return $this.Rotate(1)
    }

    [TriangleSymbol] RotateLeft() {
        return $this.Rotate(-1)
    }

    [TriangleSymbol] ModifyShape([Boolean]$Hollow, [Boolean]$Small) {
        $this.Effects.Hollow = $Hollow
        $this.Effects.Small = $Small
        return $this
    }

    hidden Update() {
        $this.Direction.Name = [TriangleSymbol]::DIRECTIONS[$this.Direction.Index]
    }

    [String] ToString() {
        $Value = [TriangleSymbol]::DEFINITIONS[$this.Direction.Name]
        if ($this.Effects.Hollow) {
            $Value += [TriangleSymbol]::HOLLOW_OFFSET
        }

        if ($this.Effects.Small) {
            $Value += [TriangleSymbol]::SMALL_OFFSET
        }

        return ([char] $Value).ToString()
    }

    static [char] Get([String] $Direction, [Boolean] $Hollow, [Boolean] $Small) {
        if (-not [TriangleSymbol]::DEFINITIONS.ContainsKey($Direction)) {
            throw "Invalid Triangle Direction '$Direction'"
        }
        $BaseValue = [TriangleSymbol]::DEFINITIONS[$Direction]
        if ($Hollow) {
            $BaseValue += [TriangleSymbol]::HOLLOW_OFFSET
        }

        if ($Small) {
            $BaseValue += [TriangleSymbol]::SMALL_OFFSET
        }

        return [char]$BaseValue
    }

    static [char] Get([String] $Direction, [Boolean] $Hollow) {
        return [TriangleSymbol]::Get($Direction, $Hollow, $false)
    }

    static [char] Get([String] $Direction) {
        return [TriangleSymbol]::Get($Direction, $false)
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