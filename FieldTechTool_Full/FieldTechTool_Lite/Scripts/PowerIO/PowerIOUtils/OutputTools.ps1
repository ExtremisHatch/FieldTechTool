class TextFormatStyle {
    $Elements; 

    hidden TextFormatStyle([Object[]] $Elements) {
        $this.Elements = $Elements
    }

    [StyledText] StyleText([String] $Text) {
        return [StyledText]::Create($Text).StyleText($this)
    }
}

class BoxStyle : TextFormatStyle {
    static $SQUARES = [BoxStyle]::new(@([char]9608, [char]9608, [char]9608))
    static $DOTTED = [BoxStyle]::new(@([char]9617, [char]9617, [char]9617))
    static $PLAIN = [BoxStyle]::new(@('+', '-', '|'))
    static $THIN = [BoxStyle]::new(@([char]9484, [char]9488, [char]9492, [char]9496, [char]9472, [char]9474))

    $Color;
    $InsideColor;
    $InsideCharacter;
    $Padding;

    hidden BoxStyle([Object[]] $Elements) : base($Elements) {
        $this.SetColor('') # NO COLOR BY DEEEEEFAULT
        $this.SetInsideCharacter(' ') # Space character
        $this.SetInsideColor('') # No color by default!!!!
        $this.SetPadding(0);
    }

    hidden [String] GetElement($Index) {
        # If it's a corner
        if ($this.Elements.Count -eq 3) {
            if ($Index -ge 0 -and $Index -le 3) {
                return $this.Elements[0]
            } else {
                # Turn 5/6 into 1/2 for Hori & Vert
                return $this.Elements[$Index-4]
            }
        } elseif ($this.Elements.Count -eq 6) {
            return $this.Elements[$Index]
        } else {
            throw "Invalid Element Count '$($this.Elements.Count)', expecting 3 or 6"
        }
    }

    hidden [String] GetHorizontalPiece() {
        return $this.GetElement(4)
    }

    hidden [String] GetVerticalPiece() {
        return $this.GetElement(5)
    }

    hidden [String] GetCornerPiece($Corner) { 
        if ($Corner -gt 3 -or $Corner -lt 0) {
            throw "Invalid Corner '$Corner', expected 0-3"
        }
        return $this.GetElement($Corner)
    }
    
    hidden [void] SetColor($Color) { if ($Color -eq $null) { $this.Color = ''; } else { $this.Color = $Color; } }

    hidden [void] SetInsideCharacter($Character) { if ($Character -eq $null) { $this.InsideCharacter = ' '; } else { $this.InsideCharacter = $Character } }

    hidden [void] SetInsideColor($Color) { if ($Color -eq $null) { $this.InsideColor = ''; } else { $this.InsideColor = $Color } }

    hidden [void] SetPadding($Padding) { if (($Padding -eq $null -or $Padding -isnot [int]) -or $Padding -lt 1) { $this.Padding = 0 } else { $this.Padding = $Padding } }

    static [BoxStyle] Create([BoxStyle] $Source, [String] $BoxColor, [int] $Padding, [String] $InsideColor, [String] $InsideCharacter) {
        $Style = [BoxStyle]::new($Source.Elements)
        $Style.SetColor($BoxColor)
        $Style.SetInsideCharacter($InsideCharacter)
        $Style.SetInsideColor($InsideColor)
        $Style.SetPadding($Padding)
        return $Style
    }
    
    static [BoxStyle] Create([BoxStyle] $Source, [String] $BoxColor, [int] $Padding, [String] $InsideColor) {
        return [BoxStyle]::Create($Source, $BoxColor, $Padding, $InsideColor, $Source.InsideCharacter)
    }

    static [BoxStyle] Create([BoxStyle] $Source, [String] $BoxColor, [int] $Padding) {
        return [BoxStyle]::Create($Source, $BoxColor, $Padding, $Source.InsideColor)
    }

    static [BoxStyle] Create([BoxStyle] $Source, [String] $BoxColor) {
        return [BoxStyle]::Create($Source, $BoxColor, $Source.Padding)
    }
}

class CornerStyle : TextFormatStyle {
    static $THIN = [CornerStyle]::new(@([char]8988, [char]8989, [char]8990, [char]8991))
    static $TRIANGLE = [CornerStyle]::new(@([char]9700, [char]9701, [char]9699, [char]9698))
    static $ROUND = [CornerStyle]::new(@([char]9581, [char]9582, [char]9584, [char]9583))

    $Color;
    hidden CornerStyle([Object[]] $Elements) : base($Elements) {
        $this.SetColor('')
    }
    
    hidden SetColor($Color) { if ($Color -eq $null) { $this.Color = '' } else { $this.Color = $Color } }

    static [CornerStyle] Create([CornerStyle] $Source, [String] $CornerColor) {
        $Style = [CornerStyle]::new($Source.Elements)
        $Style.SetColor($CornerColor)
        return $Style
    }
}

class StyledText {
    hidden static $DefaultWrapValues = @{Width=0; Centered=$True;}

    hidden [String] $Text;

    StyledText([String] $Text) {
        $this.Text = $Text
    }

    static [StyledText] Create($Text) {
        return [StyledText]::new($Text)
    }

    Display([Boolean] $Newline) {
        HandleTextTypesOutput -Text $this.Text -NoNewline:(-not $Newline)
    }

    Display() {
        $this.Display($true)
    }

    [String] ToString() {
        return $this.Text
    }

    [String] GetText() {
        return $this.ToString()
    }

    [StyledText] Append([String] $Text) {
        $this.Text += $Text
        return $this
    }

    [StyledText] Prepend([String] $Text) {
        $this.Text = $Text + $this.Text
        return $this
    }

    [StyledText] Insert([int] $Index, [String] $Text) {
        $this.Text = $this.Text.Insert($Index, $Text)
        return $this
    }

    [StyledText] Newline() {
        $this.Append("`n")
        return $this
    }

    <#
        Generic Style Text
    #>
    [StyledText] Style([TextFormatStyle] $Style) {
        switch ($Style) {
            {$_ -is [CornerStyle]} {
                return $this.StyleCorners($_)
            }
            {$_ -is [BoxStyle]} {
                return $this.Box($_)
            }
            default {
                throw "Unhandled/Invalid TextFormatStyle: '$($Style.GetType().FullName)'"
            }
        }
        return $this # Unneeded, but PS be thinking nOt AlL cOdE pAtHs ReTuRn VaLuE
    }

    <#
        WRAPPED TEXT
    #>

    [StyledText] Wrap([int] $Width, [boolean] $Centered) {
        $this.Text = [StyledText]::WrapText($this.Text, $Width, $Centered)
        return $this;
    }

    [StyledText] Wrap([boolean]$Centered) {
        return $this.Wrap([StyledText]::DefaultWrapValues.Width, $Centered)
    }

    [StyledText] Wrap([int] $Width) {
        return $this.Wrap($Width, [StyledText]::DefaultWrapValues.Centered)
    }

    [StyledText] Wrap() {
        return $this.Wrap([StyledText]::DefaultWrapValues.Width, [StyledText]::DefaultWrapValues.Centered)
    }

    <#
        BOXED TEXT
    #>

    [StyledText] Box([BoxStyle] $Style) {
        $this.Text = [StyledText]::BoxText($this.Text, $Style)
        return $this
    }

    <#
        CORNER DECORATIONS
    #>

    [StyledText] StyleCorners([CornerStyle] $Style) {
        $this.Text = [StyledText]::WrapTextCorners($this.Text, $Style)
        return $this
    }

    <#
        STATIC METHODS
    #>
    
    static [String] WrapTextCorners([String] $Text, [CornerStyle] $Style) {
        # Hardcoded values for tesitng
        $AdditionalHorizontalPadding = 1 # Additional gap, as one across and one up aren't equal. Do 2 across 1 up

        $Corners = $Style.Elements
        $CornerColor = $Style.Color

        $TextLength = ([TextTools]::GetLines([ColoredText]::GetUncoloredText($Text)) | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
        
        $CornerLengths = $Corners | % { $_.Length }

        $TheText = ([TextTools]::GetLines($Text) | % { return "$(" " * $AdditionalHorizontalPadding) $_&[] " }) -join "`n"

        $Spacing = ' ' * ($TextLength + ($AdditionalHorizontalPadding*2))

        $Pieces = @("&[{4}]{0}&[]$Spacing&[{4}]{1}&[]", "&[{4}]{2}&[]$Spacing&[{4}]{3}&[]") | % { $_ -f ($Corners+$CornerColor) }

        return [ColoredText]::CompressColorDefinitions(($Pieces[0], $TheText, $Pieces[1]) -join "`n")
    }

    static [String] BoxText([String] $Text, [BoxStyle] $Style) {
        $MaxWidth = ([TextTools]::GetLines([ColoredText]::GetUncoloredText($Text)) | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
        $PADDING = $Style.Padding;
        $BGCOLOR = $Style.InsideColor; # NONE; DEFAULT
        $BGCHAR = $Style.InsideCharacter # SPACE; DEFAULT
        $BoxColor = $Style.Color
        $FormattedBoxColor = "&[$BoxColor]"

        $HorizontalPiece = [char]$Style.GetHorizontalPiece()
        $VerticalPiece = [char]$Style.GetVerticalPiece()
        $CornerPieces = 0..3 | % { $Style.GetCornerPiece($_) }
        $HorizontalBarFormat = $FormattedBoxColor + "{0}" + ("$HorizontalPiece" * ($MaxWidth + ($PADDING*4))) + "{1}&[]"
        
        $topHorizontalBar = $HorizontalBarFormat -f $CornerPieces[0],$CornerPieces[1]
        $bottomHorizontalBar = $HorizontalBarFormat -f $CornerPieces[2],$CornerPieces[3]
        $verticalBar = $FormattedBoxColor + $VerticalPiece + "&[$BGCOLOR]" + ($BGCHAR * ($MaxWidth + ($PADDING*4))) + $FormattedBoxColor + $VerticalPiece + "&[]"

        $Result = [System.Collections.ArrayList]::new() 
        $Result.AddRange(($topHorizontalBar, $bottomHorizontalBar))
        for ($i = 0; $i -lt ($PADDING*2); $i++) {
            $Result.Insert(1, $verticalBar)
        }

        # Now we compile the lines of text provided
        $TextResult = @()
        foreach ($Line in [TextTools]::GetLines($Text)) {
            $LineLength = [ColoredText]::GetUncoloredText($Line).Length; 
            $RemainingLength = $MaxWidth - $LineLength;
            
            # If the Background Color is specified then we need to inject it into the
            # start and end of the line, without interrupting the content!
            if ($BGCOLOR -notlike $null) {
                $LineStartColor = (Select-String -InputObject $Line -Pattern "^( )*").Matches[0]
                $LineEndColor = (Select-String -InputObject $Line -Pattern " *$").Matches[0]

                # Insert inside/filler color on the end of actual content
                if ($LineEndColor.Length -gt 0) {
                    $Line = $Line.Substring(0, $Line.Length-$LineEndColor.Length) + "&[$BGCOLOR]$("$BGCHAR"*$LineEndColor.Length)&[]"
                }
                
                # And the same for the start
                if ($LineStartColor.Length -gt 0) {
                    $Line = "&[$BGCOLOR]$("$BGCHAR" * $LineStartColor.Length)&[]" + $Line.Substring($LineStartColor.Length)
                }
            }

            $TextResult += "&[$BoxColor]$VerticalPiece&[$BGCOLOR]$($BGCHAR * ($PADDING*2))&[]$Line&[$BGCOLOR]$($BGCHAR * ($RemainingLength+($PADDING*2)))&[$BoxColor]$VerticalPiece&[]"
        }

        $Result.Insert($Result.Count/2, ($TextResult -join "`n"))

        return [ColoredText]::CompressColorDefinitions($Result -join "`n")
    }

    static [Object] WrapText([String] $Text, [int] $Width, [boolean]$Centered) {
        # Get Color Definitions
        $Definitions = [ColoredText]::GetColorDefinitions($Text)
        # Make the text plain
        $TheText = $Uncolored = [ColoredText]::GetUncoloredText($Text);
        
        # Calculate text width when no Width provided
        $TextWidth = ([TextTools]::GetLines($Uncolored) | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
        if ($Width -eq $null -or $Width -eq 0) {
            $Width = $TextWidth
        }

        # Result Array, will store each individual line
        $Result = @()

        # Start of sentence/text processing

        # Current TotalIndex throughout the string
        # Utilized for reinserting color definitions
        $TotalIndex = 0;
        
        # Last Color used, for keeping color wrapping across lines
        $LastColor = $null;
        
        # Each Portion is each set of text between Newlines
        $Portions = [TextTools]::GetLines($TheText)
        foreach ($Portion in $Portions) {
            # Portion here '1234' out of '1234`n12341234'
            $Remaining = $Portion # Remaining Text in this portion
            
            # PieceCount of how many Pieces this Portion
            $PieceCount = 0;

            # While Portion still has more to consume
            while ($Remaining.Length -gt 0) {
                $Result += "" # Current result, referenced via Result[-1]

                # Work out MaxPieceSize & the Segment on loop
                # We do this so we can remove excess spaces
                $MaxPieceSize = [Math]::Min($Remaining.Length, $Width)
                $Segment = $Remaining.Substring(0, $MaxPieceSize)

                # Now that we have our Segment, we need to cut this down into our 'Piece'

                # If remaining length isn't equal to MaxPieceSize, it needs cutting
                $NeedsCutting = $Remaining.Length -ne $MaxPieceSize
                
                # If next char is a space (after our cut)
                $CutOutSpace = $Remaining.Length -gt $MaxPieceSize -and $Remaining[$MaxPieceSize] -match "[ ]"

                if ($NeedsCutting) {
                    # Two Patterns for optimal spacing
                    [Object[]] $SpaceLetter = (Select-String -InputObject $Segment -Pattern " [^ ]" -AllMatches).Matches | Where-Object { $_.Index -ne 0 } | % { $_.Index }
                    [Object[]] $LetterSpace = (Select-String -InputObject $Segment -Pattern "[^ ] " -AllMatches).Matches | Where-Object { $_.Index -ge 0 } | % { $_.Index + 1 }

                    # (Hopefully) optimal space to split it at
                    $OptimalSpace = ($SpaceLetter+$LetterSpace+,@(-1) | Sort-Object -Descending)[0]

                    # Target Size of this piece
                    # If we cut off a space already, no need to look for a space to cut off
                    # Otherwise, if an optimal space exists then cut there
                    # Finally, if neither of the above, just make it the max size and cut any remaining letters from word
                    $TargetSize = if ($CutOutSpace) {$MaxPieceSize} elseif ($OptimalSpace -ne -1) { $OptimalSpace } else { $MaxPieceSize }
                    
                    # Set current Piece & trim 'Remaining' text
                    $Piece = $Remaining.Substring(0, $TargetSize)
                    $Remaining = $Remaining.Substring($TargetSize) # Remove from Remaining
                } else {
                    # Set current Piece & trim 'Remaining' text
                    $Piece = $Remaining.Substring(0, $MaxPieceSize)
                    $Remaining = $Remaining.Substring($MaxPieceSize) # Remove from Remaining
                }

                # Length of our raw Piece (before colors inserted, etc)
                $PieceLength = $Piece.Length

                # Additional Index Leniency, for when we find a match in the current line
                # If we find a match, expand search index by match length as to not affect the 'true' index
                $AdditionalIndex = 0;

                # Find color definitions relevant to this portion of text
                # Do this by filtering the definitions down to ones in our current index range
                $RelevantDefinitions = $Definitions | Where-Object { ($_.Value -ne $null) -and 
                                                                     ($_.Index -ge $TotalIndex) -and 
                                                                     $_.Index -le ($TotalIndex+$PieceLength+$AdditionalIndex) -and 
                                                                     (($AdditionalIndex += $_.Value.Length) -ne $False) }
                #$RelevantDefinitions | Out-Host
                # Save/Record original length for TotalIndex
                $OriginalPieceLength = $Piece.Length
                $OriginalLastColor = $LastColor

                # Modify the Piece
                $ModifyOffset = 0; # For offsetting within this line
                $RelevantDefinitions | % { $CalcPos = $_.Index-$TotalIndex; # Write-Host "449Inserting: '$($_.Value)' at $CalcPos in '$Piece' [$($_.Index);$TotalIndex]"
                                           $Piece = $Piece.Insert($CalcPos, $_.Value);
                                           $ModifyOffset+= $_.Value.Length; $LastColor = $_ }
                
                # Insert any previous color from end of last line into the start of this line
                # Only if the start of this line doesn't already have a color definition
                if ($OriginalLastColor -ne $null -and ($Definitions | Where-Object { ($_.Index-$TotalIndex) -eq 0}) -eq $null) {
                    $Piece = $Piece.Insert(0, $OriginalLastColor.Value)
                }

                # Final Pieces: Incrementing TotalIndex, and putting together final Piece
                $TotalIndex += $PieceLength
                $TotalIndex += $ModifyOffset
                
                $Result[-1] += $Piece
                $PieceCount++

                # Center the text if needed
                if ($Centered) {
                    $TotalPadding = $Width - $OriginalPieceLength
                    $Remainder = $TotalPadding % 2
                    $Split = ($TotalPadding - $Remainder) / 2
                    # Set the value with spaces for centering
                    # Insert color reset after Piece too, so spaces don't catch Background color
                    $Result[-1] = "$(' ' * ($Split+$Remainder))$($Result[-1])&[]$(' ' * ($Split))"
                }

                # If there's a space after this Piece, let's consume it now!
                if ($CutOutSpace -or $Remaining[0] -match "[ ]") {
                    if (($Definition = ($Definitions | Where-Object { $_.Index -eq $TotalIndex })) -ne $null) {
                       $LastColor = $Definition   
                       $TotalIndex += $Definition.Value.Length

                       # Add it onto the end of current Result
                       $Result[-1] += $Definition.Value
                    }

                    # Consume 1 char
                    $TotalIndex++;
                    $Remaining = $Remaining.Substring(1)
                }
            }

            # If it was a Newline with no content, we have empty line!
            if ($PieceCount -eq 0) {
                $Result+=""
            }

            # Increment TotalIndex by 1 at the end of each iteration
            # This accounts for NewLine characters
            $TotalIndex++;
        }

        return [ColoredText]::CompressColorDefinitions($Result -join "`n")
    }
}