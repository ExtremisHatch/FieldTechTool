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
                $PositionInfo = $fields[2].Split("`n")

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

            $ErrorText = ($Format -join "`n") -f $fields
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

class TextStyler {

    static $CORNER_STYLES = @{
        THIN=@([char]8988, [char]8989, [char]8990, [char]8991);
        TRIANGLE=@([char]9700, [char]9701, [char]9699, [char]9698)
    }

    static $BOX_STYLES = @{
        SQUARES=@([char]9608,[char]9608,[char]9608);
        DOTTED=@([char]9617,[char]9617,[char]9617)
        PLAIN=@('-','|','+')
    }

    static [String] WrapTextCorners([String] $Text, [Int[]] $Corners, $CornerColor="") {
        $TextLength = ([ColoredText]::GetUncoloredText($Text).Split("`n") | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
        return "&[$CornerColor]$([char]$Corners[0])&[]$(' ' * $TextLength)&[$CornerColor]$([char]$Corners[1])&[]`n $Text `n&[$CornerColor]$([char]$Corners[2])&[]$(' ' * $TextLength)&[$CornerColor]$([char]$Corners[3])"
    }

    static [String] BoxText([String] $Text, [Object[]] $Style=[TextStyler]::BOX_STYLES.PLAIN, $BoxColor="") {
        $PADDING = 0;
        $BGCOLOR = ''; # NONE; DEFAULT
        $BGCHAR = ' ' # SPACE; DEFAULT
        # TODO: Some sort of builder for these text styles instead?

        $Uncolored = [ColoredText]::GetUncoloredText($Text)
        $Width = ($Uncolored.Split("`n") | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
        #Write-Host "Width is: $Width"
        #Write-Host "Text: '$Uncolored'"
        #Write-Host "$($Uncolored.length)"
        $DoBoxColoring = -not ($BoxColor -like '')
       
        $BoxColorFormat = "&[$BoxColor]"

        # No need to wrap it on behalf of user 
        #$Text = [TextStyler]::WrapText($Text, $Width, $False)

        $HorizontalPiece = [char]$Style[0]
        $VerticalPiece = [char]$Style[1]
        $CornerPiece = [char]$Style[2]

        if ($DoBoxColoring) {
            $horizontalBar = $BoxColorFormat + $CornerPiece + ("$HorizontalPiece" * ($Width + ($PADDING*2))) + $CornerPiece
            $verticalBar = $BoxColorFormat + $VerticalPiece + "&[$BGCOLOR]" + ($BGCHAR * ($Width + ($PADDING*2))) + $BoxColorFormat + $VerticalPiece
        } else {
            $horizontalBar = $CornerPiece + ("$HorizontalPiece" * ($Width + ($PADDING*2))) + $CornerPiece
            $verticalBar = $VerticalPiece + "&[$BGCOLOR]" + ($BGCHAR * ($Width + ($PADDING*2))) + $VerticalPiece
        }
        
        #$Result = @($horizontalBar, $verticalBar, $null, $verticalBar, $horizontalBar)
        $Result = @($horizontalBar)
        for ($i = 0; $i -lt $PADDING; $i++) {
            $Result += $verticalBar
        }

        $TextResult = @()
        foreach ($bit in $Text.Split("`n")) {
            $HasColor = [ColoredText]::IsColored($bit)
            $PieceLength = [ColoredText]::GetUncoloredText($bit).Length; 
            $RemainingLength = $Width - $PieceLength;

            $TextResult += "&[$BoxColor]$VerticalPiece&[$BGCOLOR]$($BGCHAR * $PADDING)$bit&[$BGCOLOR]$($BGCHAR * $RemainingLength)&[]$($BGCHAR * $PADDING)&[$BoxColor]$VerticalPiece"
        }
        $Result += ($TextResult -join "`n")
        
        for ($i = 0; $i -lt $PADDING; $i++) {
            $Result += $verticalBar
        }
        $Result += $horizontalBar

        return $Result -join "`n"
    }

    static [Object] WrapText([String] $Text, [int] $Width, [boolean]$Center=$True) {
        # Get Color Definitions
        $Definitions = [ColoredText]::GetColorDefinitions($Text)
        # Make the text plain
        $Text = $Uncolored = [ColoredText]::GetUncoloredText($Text);
        
        # Calculate text width for no Width provided
        $TextWidth = ($Uncolored.Split("`n") | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
        if ($Width -eq $null -or $Width -eq 0) {
            $Width = $TextWidth
        }

        #Write-Host "Max Width: $Width"

        # Results Array, containing each line
        $Result = @()

        # TotalIndex Passed, INCLUDING any color text stuff
        $TotalIndex = 0;

        # Last Color inserted
        $LastColor = $null
        
        :IterateWords
        while ($Text.Length -ne 0) {
            # Create new object in Result array, will modify this
            $Result += ""

            # Using a 'while' loop we keep catching these until no more and we have text
            $NewlineFoundCount = 0;
            while ($Text[0] -match "`n") {
                $MatchChar = $Text[0]
                #Write-Host "Match: '$Text' ($MatchChar)"
                #Write-Host "TI: $TotalIndex"
                #$Definitions | Out-Host

                # This function catches Colors that were at the end of the last line (or current line)
                # And adds them onto the end of the previous (or current) line
                if (($Definition = ($Definitions | Where-Object { $_.Index -eq $TotalIndex })) -ne $null) {
                    #Insert color definition into the end of the last line
                    if ($TotalIndex -eq 0) {
                        #Write-Host "351Inserting '$($Definition.Value)' into '$($Result[-1])'"  
                        $Result[-1] += $Definition.Value    
                    } else {
                        #Write-Host "353Inserting '$($Definition.Value)' into '$($Result[-2])'"  
                        $Result[-2] += $Definition.Value
                    }  
                    $TotalIndex+=$Definition.Value.Length
                    $LastColor = $Definition
                }
                
                # Increase Index by 1 as we're cutting the character at the start off
                $TotalIndex++; 
                $Text = $Text.Substring(1)

                # If it's not a space but instead a Newline, insert empty result
                if ($MatchChar -eq "`n") {
                    $NewlineFoundCount++;
                    
                    if ($NewlineFoundCount -gt 1) {
                        $Result+= ""
                    }
                    #Write-Host "Match is NL"
                }
            }

            $FirstSpace = $Text.IndexOf(' ');

            # Not the first line, and space is at the start. We simply cut cut cut (assuming last char wasn't space)
            # This fixes any spaces between words after a cut, tho is a little buggy and double places colors sometimes
            # Need a better alternative in future, potentially, may also just be a permanent temp fix
            if ($TotalIndex -ne 0 -and $FirstSpace -ne -1 -and $FirstSpace -eq 0) {
                $LastLineLastChar = $Result[-2][-1]
                if ($LastLineLastChar -ne ' ') {
                    if (($Definition = ($Definitions | Where-Object { $_.Index -eq $TotalIndex })) -ne $null) {
                        #Write-Host "396Inserting '$($Definition.Value)' into '$($Result[-1])'"  
                        $Result[-1] += $Definition.Value 
                        $LastColor = $Definition   
                    }
                    $TotalIndex++;
                    $Text = $Text.Substring(1);
                }
            }

            $TargetIndex = $MaxSearch = [Math]::Min($Width, $Text.Length)
            
            # String we're searching
            $SearchArea = ($Text[0..($TargetIndex-1)] -join '')

            if (($NLIndex = $SearchArea.IndexOf("`n")) -ne -1) {
                #Write-Host "Changing TargetIndex: $TargetIndex -> $NLIndex"
                $TargetIndex = [Math]::Min($TargetIndex, $NLIndex)
            }
            

            # If TargetIndex is still Width (Not cutting it short as newly defined area)
            # and if Text Length is greater than width (Otherwise no need to cut it)
            if (($TargetIndex -eq $Width) -and $Text.Length -gt $Width) {
                # Two Patterns for optimal spacing
                [Object[]] $SpaceLetter = ,(Select-String -InputObject $SearchArea -Pattern " [^ ]" -AllMatches).Matches | Where-Object { $_.Index -ne 0 } | % { $_.Index }
                [Object[]] $LetterSpace = ,(Select-String -InputObject $SearchArea -Pattern "[^ ] " -AllMatches).Matches | Where-Object { $_.Index -ge 0 } | % { $_.Index + 1 }
                
                # (Hopefully) optimal space to split it at
                $OptimalSpace = ($SpaceLetter+$LetterSpace+@(-1) | Sort-Object -Descending)[0]

                #Write-Host ($SpaceLetter+$LetterSpace+@(-1))
                #Write-Host "OptimalSpace: $OptimalSpace"

                # If it's all spaces up to the optimal space, we just cut the word and wrap it. 
                # Users error not mine!
                if ((($Text[0..$OptimalSpace]) | Where-Object {$_ -ne ' '}).Count -eq 0) {
                  #Write-Host "Only Spaces leading up to OptimalSpace $OptimalSpace`: '$(($Text[0..$OptimalSpace]))'"
                  # Do nothing in here, but by being here we aren't at the next 'if' setting TI

                  # If it's not -1 we set TargetIndex to that location
                  # Otherwise, target index is the width  
                } elseif ($OptimalSpace -ne -1) {
                    #Write-Host "Set TI to OS: $OptimalSpace"
                    $TargetIndex = $OptimalSpace
                }
            }

            #Write-Host "TI: $TargetIndex"
            #Write-Host "Text: '$Text'"
            $Segment = ($Text.Substring(0, ($TargetIndex)))
            #Write-Host "Segment: '$Segment'"
            
            # Cut the text remaining down
            $Text = $Text.Substring($TargetIndex)
            $Pieces = $Segment.Split("`n")
            
            for ($i = 0; $i -lt $Pieces.Count; $i++) {
            # The current Piece of the Segment (or the Segment)
            $Piece = $Pieces[$i]
            #Write-Host "Piece: '$Piece'"
            
            # If Piece is empty, it's caused by a newline at the start of segment
            # Or two newlines, and is the inbetween.
            # Simply increase the index and add the empty line, then continue (restart loop)
            if ($Piece.Length -eq 0) {
                $TotalIndex++;
                #$Result[-1]+='' # Newline # Deprecated, continuing works as line already added in results
                #Write-Host "NL"
                continue;
            }

            ## Replace (ONLY) first space at start of line, and only if it was split/isn't first piece
            ## Also don't replace spaces after Newlines, as they're most likely intentional else user error
            #if ($TotalIndex -ne 0 -and $i -eq 0) {
            #    #$Piece = $Piece -replace "^ "
            #    if ($Piece -ne $Pieces[$i]) {
            #        #$TotalIndex++; # Account for removed space
            #    }
            #}

            $SectionLength = $Piece.Length

            # Additional Index Leniency, for when we find a match in the current line
            # If we find a match, expand search index by match length as to not affect the 'true' index
            $AdditionalIndex = -1;

            # Find color definitions relevant to this portion of text
            # Do this by filtering the definitions down to ones in our current index range
            $RelevantDefinitions = $Definitions | Where-Object { ($_.Value -ne $null) -and 
                                                                 ($_.Index -ge $TotalIndex) -and 
                                                                 $_.Index -le ($TotalIndex+$SectionLength+$AdditionalIndex) -and 
                                                                 (($AdditionalIndex += $_.Value.Length) -ne $False) }
            #$RelevantDefinitions | Out-Host
            # Save/Record original length for TotalIndex
            $OriginalPieceLength = $Piece.Length
            $OriginalLastColor = $LastColor

            # Modify the Piece
            $ModifyOffset = 0; # For offsetting within this line
            $RelevantDefinitions | % { $CalcPos = $_.Index-$TotalIndex;  #Write-Host "449Inserting: '$($_.Value)' at $CalcPos in '$Piece' [$($_.Index);$TotalIndex]"
                                       $Piece = $Piece.Insert($CalcPos, $_.Value);
                                       $ModifyOffset+= $_.Value.Length; $LastColor = $_ }
            
            # Add the last color from the last line
            # ONLY if there was nothing placed at index 0 on this line already
            if ($OriginalLastColor -ne $null -and ($RelevantDefinitions | Where-Object { ($_.Index-$TotalIndex) -eq 0 }) -eq $null) {
                #Write-Host "455Inserting originallastcolor: '$($OriginalLastColor.Value)' into '$Piece'"
                $Piece = $Piece.Insert(0, $OriginalLastColor.Value) # We do this at the end, so no need to modify index values as next line is unaffected
            }
            
            if ($Center) {
                $RemainingLength = $Width - $OriginalPieceLength
                $Remainder = ($RemainingLength%2)
                $Left = ($RemainingLength - $Remainder) / 2
                $Right = $Left + $Remainder
                $Piece = $Piece.Insert(0, (" "*$Left))
                $Piece = $Piece.Insert($Piece.Length, (" "*$Right))
            }

            # Add the completed Piece to the current Result Index
            $Result[-1] += $Piece
            
            # Increment TotalIndex
            $TotalIndex += ($SectionLength + $ModifyOffset)
        }}

        #Write-Host "Results:" -ForegroundColor Cyan
        return ($Result -join "`n")
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