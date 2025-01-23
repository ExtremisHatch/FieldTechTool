<#

    PowerIO TextTools

#>

class ColoredText {
    static [HashTable] $ContrastColors = @{
        BLACK='WHITE'; DarkBlue='WHITE'; DarkGreen='WHITE'; DarkCyan='WHITE'; DarkRed='WHITE'; DarkMagenta='WHITE'; DarkYellow='WHITE';
        Gray='WHITE'; DarkGray='WHITE'; Blue='WHITE'; Green='BLACK'; Cyan='BLACK'; Red='WHITE'; Magenta='WHITE'; Yellow='BLACK'; White='BLACK';
    }

    # I've actually impressed myself with the creation of this regex
    # I am able to pull colors from string utilizing 'groups' from the regex
    hidden static $RegexFormat = "(&\[)([A-z]*)(;?)([A-z]*)(\])"
    
    # Format:
    # Foreground color
    # "Text &[foreground]"
    # Background color
    # "Text &[;background]"
    # Both colors
    # "Text &[foreground;background]"
    hidden [String] $Text;
    hidden [OutputText] $OutputText;

    ColoredText([String] $Text) {
        $this.Text = $Text;
    }

    [String] ToString() {
        return $this.Text
    }
    
    # GetRawText sounds like it'd include formatting
    # Went with GetUncoloredText, sounds/feel specific enough
    static [String] GetUncoloredText($ColoredText) {
        $TextValue = if ($ColoredText -is [ColoredText]) { $ColoredText.Text } elseif ($ColoredText -is [String]) { $ColoredText } else { throw "Unsupported type '$($ColoredText.GetType())' for [ColoredText]::GetUncoloredText"}
        
        $Matches = (Select-String -Pattern ([ColoredText]::RegexFormat) -InputObject $TextValue -AllMatches).Matches
        $Uncolored = ""

        $LastIndex = -1;
        $Matches | % { $Uncolored += $TextValue.Substring($LastIndex+1, $_.Index-($LastIndex+1)); $LastIndex=(($_.Index+$_.Length)-1) }

        $Uncolored += $TextValue.Substring($LastIndex+1)
        return $Uncolored;
    }

    static [Hashtable[]] GetColorDefinitions($ColoredText) {
        $TextValue = if ($ColoredText -is [ColoredText]) { $ColoredText.Text } elseif ($ColoredText -is [String]) { $ColoredText } else { throw "Unsupported type '$($ColoredText.GetType())' for [ColoredText]::GetUncoloredText"}

        $Matches = (Select-String -Pattern ([ColoredText]::RegexFormat) -InputObject $TextValue -AllMatches).Matches

        $Definitions = @()
        $TotalOffset = 0

        $Matches | % { $Definitions += @{Value=$_.Value;Index=$_.Index}; $TotalOffset += $_.Length }

        $Definitions += @{TotalOffset=$TotalOffset}

        return $Definitions
    }

    static [String] InsertColorDefinitions([String] $Text, [Hashtable[]] $Definitions) {
        $Count = $Definitions.Count - 2
        $TotalOffset = $Definitions[$Count+1].TotalOffset
        $Result = $Text
        for ($i = $Count; $i -ge 0; $i--) {
            $Data = $Definitions[$i]
            $TotalOffset -= $Data.Value.Length
            $OffsetIndex = $Data.Index - $TotalOffset
            
            #Write-Host "Inserting '$($Data.Value)' at index $OffsetIndex (Original: $($Data.Index))"
            $Result = $Result.Insert($OffsetIndex, $Data.Value)
        }

        return $Result
    }

    Display([boolean] $Newline=$True) {
        $this.ToOutputText().Display($Newline)
    }

    Display() {
        $this.Display($True)
    }

    [OutputText] ToOutputText() {
        if ($this.OutputText -ne $null) {
            return $this.OutputText;
        }

        $ValidColors = [Enum]::GetValues([System.ConsoleColor])

        $Matches = (Select-String -Pattern ([ColoredText]::RegexFormat) -InputObject $this.Text -AllMatches).Matches
        $CreatedOutput = [OutputText]::new()

        $LastMatchEnd = -1;
        $ForegroundColor = $BackgroundColor = $null
        for ($i=0; $i -lt $Matches.Count; $i++) {
            $Match = $Matches[$i]
            $MatchStart = $Match.Groups[0].Index
            $MatchEnd = $Match.Groups[5].Index

            if ($MatchStart -gt $LastMatchEnd) {
                $CreatedOutput.Add($This.Text.Substring($LastMatchEnd+1, ($MatchStart - ($LastMatchEnd+1))), $ForegroundColor, $BackgroundColor)
            }

            $FGMatch = $Match.Groups[2]
            $BGMatch = $Match.Groups[4]
            
            # If specified reset, or empty color assigning, reset colors
            if ($FGMatch -ilike 'reset' -or $Match.Length -eq 3) {
                $ForegroundColor = $BackgroundColor = $null;
            } elseif (@($FGMatch, $BGMatch) -like 'highlight') {
                # Use Foreground color as Background
                # And find the best foreground color to highlight
                
                # If FG color is 'highlight', highlight it based on previous color
                if ($FGMatch -like 'highlight') {
                    $LastColors = $CreatedOutput.GetLastColor();
                    $LastForeground = $LastColors.Foreground

                    # ToString() the Color, as it may be Enum Color
                    # But first, convert color to ConsoleColor to be certain the full name is available
                    $Contrast = [ColoredText]::ContrastColors[([System.ConsoleColor]$LastForeground).ToString()]

                    $ForegroundColor = $Contrast
                    $BackgroundColor = $LastForeground

                # Else if it's the BG Color that's 'highlight', check FG color exists
                } elseif ($FGMatch.Length -ge 1) {
                    # Same as above, convert to ConsoleColor so we have the full color name and not partial
                    $Contrast = [ColoredText]::ContrastColors[([System.ConsoleColor]$FGMatch.Value).ToString()]
                    $ForegroundColor = $Contrast
                    $BackgroundColor = $FGMatch
                }
            } else {
                $ForegroundColor = $FGMatch
                $BackgroundColor = $BGMatch
            }
            $LastMatchEnd = $MatchEnd
        }

        if ($LastMatchEnd -lt $this.Text.Length) {
            $CreatedOutput.Add($This.Text.Substring($LastMatchEnd+1, ($this.Text.Length - ($LastMatchEnd+1))), $ForegroundColor, $BackgroundColor)
        }
        
        $this.OutputText = $CreatedOutput

        return $CreatedOutput;
    }

    static Display([String] $Text, [Boolean] $Newline=$True) {
        if ([ColoredText]::IsColored($Text)) {
            [ColoredText]::New($Text).Display($Newline)
        } else {
            Write-Host $Text -NoNewline:(-not $Newline)
        }
    }

    static Display([String] $Text) {
        [ColoredText]::Display($Text, $True)
    }

    [boolean] static IsColored($Object) {
        if ($Object -eq $null) { return $false; }
        
        switch ($Object.GetType()) {
            ([ColoredText]) {
                return $true
            }
            ([String]) {
                return $Object -match [ColoredText]::RegexFormat
            }
            default: { return $Object.ToString() -match [ColoredText]::RegexFormat }
        }

        # Technically do not need this, however Powershell ISE is silly
        return $false
   }
}

# OutputText made up of OutputPiece's 
class OutputText {
    hidden [Collections.Generic.List[OutputPiece]] $Pieces = @()
    hidden [boolean] $PiecesInheritColor = $false

    OutputText() {
        $this.init("", $null, $null)
    }

    OutputText([string] $Text) {
        $this.init($Text, $null, $null)
    }
    
    OutputText([String] $Text, [String] $ForegroundColor) {
        $this.init($Text, $ForegroundColor, $null)
    }

    OutputText([String] $Text, $ForegroundColor, $BackgroundColor) {
        $this.init($Text, $ForegroundColor, $BackgroundColor)
    }

    OutputText([OutputPiece] $Piece) {
        $this.Add($Piece)
    }

    hidden [void] init([String] $Text, $ForegroundColor, $BackgroundColor) {
        $this.Add($Text, $ForegroundColor, $BackgroundColor)
    }

    [OutputText] InheritColor([boolean] $Value) {
        $this.PiecesInheritColor = $Value
        return $this
    }

    [boolean] IsColorInheriting() {
        return $this.PiecesInheritColor
    }

    [OutputPiece] GetLastPiece() {
        if ($this.Pieces.Count -eq 0) { 
            return $this.Add("").GetLastPiece() 
        } else { 
            return $this.Pieces[-1]
        }
    }

    [OutputPiece[]] GetPieces() {
        return $this.Pieces
    }
    
    [int] GetPiecesCount() {
        return $this.Pieces.Count
    }

    [OutputPiece] Get([int] $Index) {
        return $this.Pieces[$Index]
    }

    [OutputText] Insert([int] $index, [OutputPiece] $OutputPiece) {
        $this.Pieces.Insert($index, $OutputPiece)
        return $this
    }

    [OutputText] Add([String] $Text) {
        return $this.Add([OutputPiece]::new($Text))
    }

    [OutputText] Add([OutputPiece] $OutputPiece) {
        return $this.Insert($this.Pieces.Count, $OutputPiece)
    }

    [OutputText] Add([String] $Text, $ForegroundColor) {
        return $this.Add([OutputPiece]::new($Text, $ForegroundColor))
    }

    [OutputText] Add([String] $Text, $ForegroundColor, $BackgroundColor) {
        return $this.Add([OutputPiece]::new($Text, $ForegroundColor, $BackgroundColor))
    }

    [OutputText] NewLine() {
        $this.Add("`n")
        return $this
    }
    
    [void] Display([boolean]$NewLine) {
        $LastPiece = $null
        foreach ($Piece in $this.Pieces) {
            # Skip Empty pieces (Typically first piece is empty)
            if ($Piece.IsEmpty()) { continue }
        
            if ($this.IsColorInheriting() -and $LastPiece -ne $null) {
                $fg = $LastPiece.ForegroundColor
                $bg = $LastPiece.BackgroundColor
        
                if ($Piece.HasForegroundColor()) { $fg = $Piece.ForegroundColor }
                if ($Piece.HasBackgroundColor()) { $bg = $Piece.BackgroundColor }
        
                $Piece.Display($fg, $bg)
            } else {
                $Piece.Display()
            }
        
            $LastPiece = $Piece
        }
        
        Write-Host -NoNewline:(-not $NewLine)
    }
    
    # Unused method ; was an attempt at grouping matching colored text for performance
    # If lots of pieces are defined individually but all match, this method may be quicker
    # This precomputes everything, then displays, thus eliminating delay mid display and pushing it all before
    [void] QuickDisplay([boolean]$NewLine) {
        $Collections = @()
        for ($i = 0; $i -lt $this.Pieces.Count; $i++) {
            $Current = $this.Pieces[$i]
            $MatchingPieces = $null
            while (($NextPiece = $this.Pieces[$i+1]) -ne $null) {
                if ($Current.MatchesColor($NextPiece) -or ($this.IsColorInheriting() -and -not $NextPiece.HasColorSet())) {
                    if ($MatchingPieces -eq $null) {
                        $MatchingPieces = @($Current, $NextPiece); # Bundling Pieces
                    } else {
                        $MatchingPieces += $NextPiece; # Adding Piece to bundle
                    }
                    $i++
                } else {
                    break;
                }
            }

            if ($MatchingPieces -ne $null) {
                $Collections += ,$MatchingPieces; # Adding MatchingPieces bundle
            } else {
                $Collections += $Current; # Adding Single Piece
            }
        }
        
        foreach ($Thing in $Collections) {
            # If Singular, $Thing[0] is the object, if a List then $Thing[0] is the first
            # Same line works for both types of data
            Write-Host ($Thing.Text -join '') -ForegroundColor $Thing[0].ForegroundColor -BackgroundColor $Thing[0].BackgroundColor -NoNewline
        }

        if ($NewLine) { Write-Host "" } # Newline at the end
    }

    [void] Display() {
        $this.Display($true)
    }

    [OutputText] Foreground([String] $ForegroundColor) {
        $this.GetLastPiece().SetForegroundColor($ForegroundColor)
        return $this
    }

    [OutputText] Background([String] $BackgroundColor) {
        $this.GetLastPiece().SetBackgroundColor($BackgroundColor)
        return $this
    }

    [OutputText] Color([String] $ForegroundColor, [String] $BackgroundColor) {
        $this.GetLastPiece().SetForegroundColor($ForegroundColor)
        $this.GetLastPiece().SetBackgroundColor($BackgroundColor)
        return $this
    }

    # No Output Return
    [void] NO() {
    }

    [OutputText] Clone() {
        $cloned = [OutputText]::new()
        $cloned.Pieces = $this.Pieces.Clone();
        $cloned.PiecesInheritColor = $this.PiecesInheritColor

        return $cloned
    }

    [Hashtable] GetLastColor() {
        if ($this.IsColorInheriting()) {
            $AllPieces = $this.GetPieces()
            $LastColor = @{Foreground=$null;Background=$null}
            for ($i = $AllPieces.Count - 1; $i -gt 0; $i--) {
                $CurrentPiece = $AllPieces[$i]

                # Don't overwrite as we go backwards
                if ($LastColor.Foreground -eq $null -and $CurrentPiece.HasForegroundColor()) {
                    $LastColor.Foreground = $CurrentPiece.GetForegroundColor()
                }
                
                # Same as above
                if ($LastColor.Background -eq $null -and $CurrentPiece.HasBackgroundColor()) {
                    $LastColor.Background = $CurrentPiece.GetBackgroundColor()
                }

                # Don't return until we find both, otherwise run til the end and return what we have
                if ($LastColor.Background -ne $null -and $LastColor.Foreground -ne $null) {
                    return $LastColor
                }
            }

            # If found none, use this method to get the 'default' color for the environment
            if ($LastColor.Foreground -eq $null) { $LastColor.Foreground = $this.GetLastPiece().GetForegroundColor() }
            if ($LastColor.Background -eq $null) { $LastColor.Background = $this.GetLastPiece().GetBackgroundColor() }

            return $LastColor
        } else {
            $LastPiece = $this.GetLastPiece()
            return @{Foreground=$LastPiece.GetForegroundColor(); Background=$LastPiece.GetBackgroundColor()}
        }
    }
}

class OutputPiece {
    hidden [String] $Text

    # Foreground & Background Color
    hidden [System.ConsoleColor] $ForegroundColor
    hidden [System.ConsoleColor] $BackgroundColor

    # Color set by user, used to ensure we don't default to the wrong color
    hidden [String] $SetFGColor
    hidden [String] $SetBGColor

    
    OutputPiece() {
        $this.init("", $null, $null)
        $this.SetFGColor = $this.SetBGColor = $null
    }

    OutputPiece([String] $Text) {
        $this.init($Text, $null, $null)
        $this.SetFGColor = $this.SetBGColor = $null
    }

    OutputPiece([String]$Text, [String]$ForegroundColor) {
        $this.init($Text, $ForegroundColor, $Global:host.UI.RawUI.BackgroundColor)
        $this.SetBGColor = $null
    }

    OutputPiece([String] $Text, [String] $ForegroundColor, [String] $BackgroundColor) {
        $this.init($Text, $ForegroundColor, $BackgroundColor)
    }

    hidden [void] init([string] $Text, [String] $ForegroundColor, [String] $BackgroundColor) {
        $this.Text = $Text
        
        if (-not ($ForegroundColor -like $null)) {
            $this.ForegroundColor = $this.SetFGColor = $ForegroundColor
        } else {
            $this.ForegroundColor = $Global:Host.UI.RawUI.ForegroundColor
        }

        if (-not ($BackgroundColor -like $null)) {
            $this.BackgroundColor = $this.SetBGColor = $BackgroundColor    
        } else {
            $this.BackgroundColor = $Global:Host.UI.RawUI.BackgroundColor
        }
    }

    [String] GetText() {
        return $this.Text
    }

    [boolean] IsEmpty() {
        # Null Text = No Whitespace = Background Color won't take effect = EMPTY
        return $this.Text -eq $null
    }

    [boolean] HasColorSet() {
        return $this.HasForegroundColor() -or $this.HasBackgroundColor()
    }

    [boolean] MatchesColor([OutputPiece]$Other) {
        return ($this.HasColorSet() -eq $False -and $Other.HasColorSet() -eq $False) -or 
                (($this.GetForegroundColor() -eq $Other.GetForegroundColor()) -and ($this.GetBackgroundColor() -eq $Other.GetBackgroundColor()))
    }

    [boolean] HasForegroundColor() {
        return $this.SetFGColor -notlike $null
    }

    [boolean] HasBackgroundColor() {
        return $this.SetBGColor -notlike $null
    }

    [System.ConsoleColor] GetBackgroundColor() {
        if ($this.HasBackgroundColor()) { 
            return [System.ConsoleColor]$this.SetBGColor 
        } else { 
            return $global:host.UI.RawUI.BackgroundColor 
        }
    }

    [System.ConsoleColor] GetForegroundColor() {
        if ($this.HasForegroundColor()) { 
            return [System.ConsoleColor]$this.SetFGColor 
        } else { 
            return $global:host.UI.RawUI.ForegroundColor 
        }
    }
    
    [OutputPiece] SetForegroundColor([String] $Color) {
        $this.SetFGColor = $Color
        
        if ($this.HasForegroundColor()) {
            $this.ForegroundColor = $Color
        }

        return $this
    }

    [OutputPiece] SetBackgroundColor([String] $Color) {
        $this.SetBGColor = $Color
        if ($this.HasBackgroundColor()) {
            $this.BackgroundColor = $Color
        }
        return $this
    }

    [OutputPiece] Clone() {
        $OutputPiece = [OutputPiece]::new()

        $OutputPiece.SetForegroundColor($this.SetFGColor)
        $OutputPiece.SetBackgroundColor($this.SetBGColor)
        $OutputPiece.Text = $this.Text

        return $OutputPiece
    }
    
    [void] Display() {
        # If we have BG color set, use it, otherwise use console default/current
        $fg = if ($this.HasForegroundColor()) { $this.ForegroundColor } else { $Global:host.UI.RawUI.ForegroundColor }  
        $bg = if ($this.HasBackgroundColor()) { $this.BackgroundColor } else { $Global:host.UI.RawUI.BackgroundColor } 
        $this.Display($fg, $bg)
    }

    [void] Display($ForegroundColor, $BackgroundColor) {
        Write-Host $this.Text -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewline
    }

}

# Example class for OutputPiece usage
class TimeOutputPiece : OutputPiece {

    # Only set the text when we display, that way we have accurate date/time
    [void] Display($ForegroundColor, $BackgroundColor) {
        $this.Text = (Get-Date).ToString("[(dd/MM/yy) HH:mm:ss] ")
        ([OutputPiece]$this).Display($ForegroundColor, $BackgroundColor)
    }
}

class Whiteboard {
    $width
    $height
    [Collections.Generic.List[OutputText]] $parts = @()

    Whiteboard([int] $width, [int] $height) {
        $this.width = $width
        $this.height = $height

        0..($this.height - 1) | % { 
            $ot = [OutputText]::new()
            $ot.GetPieces().Clear()

            0..($this.width - 1) | % {
                $ot.Add(' ')
            }

            $this.parts.Add($ot)
        }
    }

    [void] fill($color) {
        0..($this.height - 1) | % { 
            $y = $_
            0..($this.width - 1) | % {
                $x = $_
                $this.color($x, $y, $color)
            }
        }
    }

    [void] square($x, $y, $size, $color, $fill=$false) {
        $size--;
        foreach ($i in (0..$size)) {
            if ($fill) {
                foreach ($j in (0..$size)) {
                    $this.color($x + $i, $y + $j, $color)
                }
            } else {
                $this.color($x + $i, $y, $color)
                $this.color($x, $y + $i, $color)
                $this.color($x + $i, $y + $size, $color)
                $this.color($x + $size, $y + $i, $color)
            }
        }
    }

    [void] color($x,$y,$color) {
        $piece = $this.parts[$y].GetPieces().Get($x+1)
        $piece.SetBackgroundColor($color)
    }

    [void] display() {
        foreach ($p in $this.parts) {
            $p.Display()
        }
    }

    [void] newdisplay() {
        $this.parts.NewDisplay($true)
    }
}


<#
    TESTING FUNCTIONS
#>
function VisualTestWhiteboard() {
    $colors = [System.Enum]::GetValues([System.ConsoleColor])
    $colorCount = $colors.Count
    $wb = [Whiteboard]::new($colorCount * 3, $colorCount * 2)
    #$wb.fill('green');

    for ($i = 0; $i -lt $colors.Count; $i++) {
        $startX = $colorCount - $i;
        $startY = $colorCount - $i      
        $size = ($i * 2) + 1

        $wb.square($startX, $startY, $size, $colors[$i], $false);
    }

    $wb.newdisplay()
}

function VisualTestDotBlock() {
    $Colors = [System.ConsoleColor]::GetValues([System.ConsoleColor])
    
    $DotWidth = 2;

    foreach ($col in $Colors) {
        
        0..($DotWidth-1) | % {
            foreach ($col2 in $Colors) {
                Write-Host -NoNewline "$("$([char]9617)" * ($DotWidth*2))" -ForegroundColor $col -BackgroundColor $col2; Write-Host " " -NoNewline;
            }
        Write-Host "";
        }
        Write-Host "";
    }
}

function VisualTestTextTools() {
    # Logging time taken
    $StartTime = [DateTime]::Now

    # Testing Rainbow Colors
    Write-Host "[OutputText] Rainbow/All Colors (3x Tests)"

    $RainbowOutput = [OutputText]::new()
    $RainbowText = [OutputText]::new()
    $OppositeTest = [OutputText]::new()
    
    $Colors = [System.ConsoleColor]::GetValues([System.ConsoleColor])
    foreach ($col in $Colors) {
        $RainbowOutput.Add("Hello").Background($col) > $null
        $RainbowText.Add("[]").Foreground($col) > $null
    
        foreach ($col2 in $Colors) {
            $OppositeTest.Add("Hello").Foreground($col2).Background($col).NO()
            $OppositeTest.Add(" ").NO()
        }
        $OppositeTest.NewLine().NO()
    }
    
    Write-Host "Rainbow Backgrounds:"
    $RainbowOutput.Display()
    
    Write-Host "Rainbow Foregrounds:"
    $RainbowText.Display()
    
    Write-Host "All Combinations:"
    $OppositeTest.Display()
    

    # Testing Inheritance
    Write-Host "[OutputText] Testing Color Inheritance"

    $ColorInheritTest = [OutputText]::new()
    $ColorInheritTest.Add("Red Text").Foreground("red").NO()
    $ColorInheritTest.Add("Green Background").Background("green").NO()
    $ColorInheritTest.InheritColor($true).NO()
    $ColorInheritTest.Add("Blue Text").Foreground("Blue").NO()
    $ColorInheritTest.Add("White Background").Background("White").NO()
    

    Write-Host "Inheritance Enabled: RGBW"
    $ColorInheritTest.Display()
    
    # Testing Disabled Inheritance
    $ColorInheritTest.InheritColor($false).NO()
    Write-Host "Inheritance Disabled: RGBW"
    $ColorInheritTest.Display()
    
    # Testing Piece Cloning
    Write-Host "[OutputPiece] Testing Cloning"
    $TextPiece = [OutputPiece]::new("CLONE TEST`n") # Use \n (newline) as OutputPieces' never Newline naturally
    $TextPiece.SetBackgroundColor("red").SetForegroundColor("green") > $null
    
    $ClonedPiece = $TextPiece.Clone()
    $ClonedPiece.SetBackgroundColor("white").SetForegroundColor("blue") > $null
    
    Write-Host "Original: (R&G)"
    $TextPiece.Display()
    
    Write-Host "Cloned: (W&B)"
    $ClonedPiece.Display()
    
    # Testing Text Cloning
    Write-Host "[OutputText] Testing Cloning"
    $OutputText = [OutputText]::new("CLONE TEXT TEST")
    $OutputText.Foreground("Green").Background("Red").NO()
    
    $ClonedText = $OutputText.Clone().Foreground("Blue").Background("White");
    
    Write-Host "Original: (R&G)"
    $OutputText.Display()
    
    Write-Host "Cloned: (W&B):"
    $ClonedText.Display()
    
    $EndTime = [DateTime]::Now

    $totalTime = $EndTime.Subtract($StartTime)
    
    Write-Host "Took: $($totalTime.TotalSeconds) second(s)"
}


###