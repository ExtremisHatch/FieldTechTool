﻿class TextFormatStyle {
    $Elements; 

    hidden TextFormatStyle([Object[]] $Elements) {
        $this.Elements = $Elements
    }
}

class BoxStyle : TextFormatStyle {
    static $SQUARES = [BoxStyle]::new(@([char]9608,[char]9608,[char]9608))
    static $DOTTED = [BoxStyle]::new(@([char]9617,[char]9617,[char]9617))
    static $PLAIN = [BoxStyle]::new(@('-','|','+'))

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

    Display() {
        HandleTextTypesOutput -Text $this.Text
    }

    [String] GetText() {
        return $this.Text
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
        #if ($Corners.Count -lt 4) {
        #    throw "Corners Array requires 4 elements (received '$($Corners.Count))"
        #}

        $Corners = $Style.Elements
        $CornerColor = $Style.Color

        $TextLength = ([TextTools]::GetLines([ColoredText]::GetUncoloredText($Text)) | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
        $CornerLength = ($Corners | Sort-Object {$_.Length} -Descending)[0].Length

        # Add 1 space of padding to both sides of text
        $ExtraPadding = [Math]::Max(0, $CornerLength-1)
        $TheText = ([TextTools]::GetLines($Text) | % { " $_&[] " }) -join "`n"
                
        #0-3 = Corners, TL, TR, BL, BR & CornerColor = 4
        $Spacing = ' ' * $TextLength

        $Pieces = @("&[{4}]{0}&[]$Spacing&[{4}]{1}&[]", "&[{4}]{2}&[]$Spacing&[{4}]{3}&[]") | % { $_ -f ($Corners+$CornerColor) }

        return [ColoredText]::CompressColorDefinitions(($Pieces[0], $TheText, $Pieces[1]) -join "`n")
    }

    static [String] BoxText([String] $Text, [BoxStyle] $Style) {
        $PADDING = $Style.Padding;
        $BGCOLOR = $Style.InsideColor; # NONE; DEFAULT
        $BGCHAR = $Style.InsideCharacter # SPACE; DEFAULT
        $BoxColor = $Style.Color

        # TODO NO LONGER, I am a jeanius !! (rofl)
        # TODO: Some sort of builder for these text styles instead?

        $Uncolored = [ColoredText]::GetUncoloredText($Text)
        $Width = ([TextTools]::GetLines($Uncolored) | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
        #Write-Host "Width is: $Width"
        #Write-Host "Text: '$Uncolored'"
        #Write-Host "$($Uncolored.length)"
        $DoBoxColoring = -not ($BoxColor -like '')
       
        $BoxColorFormat = "&[$BoxColor]"

        # No need to wrap it on behalf of user 
        #$Text = [TextStyler]::WrapText($Text, $Width, $False)

        $HorizontalPiece = [char]$Style.Elements[0]
        $VerticalPiece = [char]$Style.Elements[1]
        $CornerPiece = [char]$Style.Elements[2]


        $horizontalBar = $BoxColorFormat + $CornerPiece + ("$HorizontalPiece" * ($Width + ($PADDING*4))) + $CornerPiece + "&[]"
        $verticalBar = $BoxColorFormat + $VerticalPiece + "&[$BGCOLOR]" + ($BGCHAR * ($Width + ($PADDING*4))) + $BoxColorFormat + $VerticalPiece + "&[]"

        
        #$Result = @($horizontalBar, $verticalBar, $null, $verticalBar, $horizontalBar)
        $Result = @($horizontalBar)
        for ($i = 0; $i -lt $PADDING; $i++) {
            $Result += $verticalBar
        }

        $TextResult = @()
        foreach ($bit in [TextTools]::GetLines($Text)) {
            $HasColor = [ColoredText]::IsColored($bit)
            $PieceLength = [ColoredText]::GetUncoloredText($bit).Length; 
            $RemainingLength = $Width - $PieceLength;
            
            if ($BGCOLOR -notlike $null) {
                $LineStartColor = (Select-String -InputObject $bit -Pattern "^( )*").Matches[0]
                $LineEndColor = (Select-String -InputObject $bit -Pattern " *$").Matches[0]

                # Insert inside/filler color on the end of actual content
                if ($LineEndColor.Length -gt 0) {
                    $bit = $bit.Substring(0, $bit.Length-$LineEndColor.Length) + "&[$BGCOLOR]$("$BGCHAR"*$LineEndColor.Length)&[]"
                    #$bit = $bit.Insert($bit.Length-$LineEndColor.Length, "&[$BGCOLOR]")
                }
                
                if ($LineStartColor.Length -gt 0) {
                    $bit = "&[$BGCOLOR]$("$BGCHAR" * $LineStartColor.Length)&[]" + $bit.Substring($LineStartColor.Length)
                    #$bit = "&[$BGCOLOR]$($bit.Insert($LineStartColor.Length, "&[]"))"
                }

            }

            $TextResult += "&[$BoxColor]$VerticalPiece&[$BGCOLOR]$($BGCHAR * ($PADDING*2))&[]$bit&[$BGCOLOR]$($BGCHAR * ($RemainingLength+($PADDING*2)))&[$BoxColor]$VerticalPiece&[]"
        }
        $Result += ($TextResult -join "`n")
        
        for ($i = 0; $i -lt $PADDING; $i++) {
            $Result += $verticalBar
        }
        $Result += $horizontalBar

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