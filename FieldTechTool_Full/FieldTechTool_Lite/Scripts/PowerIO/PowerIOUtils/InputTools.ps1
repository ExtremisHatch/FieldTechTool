<#

    PowerIO InputTools

#>

function HandleTextTypesOutput {
<#
    .SYNOPSIS
    Message handler for different Output types
#>
    param([Parameter(Mandatory)]$Text,
          [Switch] $NoNewline)

    switch ($Text) {
        {$_ -is [OutputText]} {
            ([OutputText]$Text).Display(-not $NoNewline)
        }

        {$_ -is [String] -or $_ -is [ColoredText]} {
            [ColoredText]::Display($Text, (-not $NoNewline))
        }
        
        default: {
            throw "Unsupported Argument Type for 'Text': $($Text.GetType())"
        }
    }
}

function QueryUser {
<#
    .SYNOPSIS
    Queries the user for a text response
#>
    param(
        [Parameter(Mandatory, Position=0)]$Question,
        [switch] $MultiLineAnswer,
        [switch] $AnswerRequired
    )

    # Output question
    HandleTextTypesOutput -Text $Question -NoNewline

    # Add spacing after question
    Write-Host " " -NoNewline

    
    if ($MultiLineAnswer) {
        $answers = @()
        while (($answer = $Host.UI.ReadLine()).length -ne 0) {
            $answers += $answer
        }
        return ($answers -join "`n")
    } else {
        while (($Response = $Host.UI.ReadLine()).Length -lt 1 -and $AnswerRequired) {
            HandleTextTypesOutput -Text "&[red]You are &[highlight]required&[red] to provide input."
        }
        return $Response
    }
}

function QueryUserSelection {
<#
    .SYNOPSIS
    Queries the user to select from a list
#>
    param( 
        [Parameter(Mandatory, Position=0)] $Question,
        [Parameter(Mandatory)][Object[]] $Answers,
        $AnswerText="Selection: ",
        $InvalidSelectionText="&[red;highlight]Invalid selection&[red]... Please try again"
    )

    # Display Question
    HandleTextTypesOutput -Text $Question #-NoNewline

    # Print Out Labelled Answers
    $choice = 0;
    $Answers | % {$choice++; Write-Host -NoNewline -ForegroundColor:$(@("Gray","White")[$choice%2]) "[$($choice)] "; HandleTextTypesOutput -Text $_; }

    Write-Host "`n" -NoNewline # NewLine prefixed before; NoNewLine for our answer

    # Read User Response
    $response = -1
    while (-not ($response -ge 1 -and $response -le $choice)) {
        HandleTextTypesOutput -Text $AnswerText -NoNewline
        
        # Try parse user input as int, if successful $response will hold value
        # if unsuccessful, $response will be 0, continuing the loop
        [int]::TryParse($Host.UI.ReadLine(), [ref]$response) > $null # Pipe result output

        # If $response -eq 0, Parse failed (or user input 0, parse succeeds), display Invalid Selection
        if ($response -eq 0) { HandleTextTypesOutput -Text $InvalidSelectionText }
    } 

    Write-Host '' # Separate answer from future output (Readability)

    return ($response-1) # Return Index of answer, rather than answer itself
}

function QueryUserKeySelection {
<#
    .SYNOPSIS
    Queries the user to select a from a list of choices with specific 'Keys'
#>
    param(
        $Question, 
        [KeySelection[]]$Selections, 
        $AnswerText="Selection: ",
        $InvalidSelectionText="&[red]Invalid selection... Please try again"
    )
    
    HandleTextTypesOutput -Text $Question
    
    $Keys = $Selections | % { $_.Key }

    $index = 0;
    $Selections | % {$index++; Write-Host "[$($_.Key)] " -ForegroundColor:@("Gray","White")[$index%2] -NoNewline; HandleTextTypesOutput -Text $_.Name }

    $Response = $null;
    while ($Response -notin $Keys) {
        # If $Response -ne $null, a (invalid) response has been provided and we're looping
        if ($Response -ne $null) { HandleTextTypesOutput -Text $InvalidSelectionText }

        HandleTextTypesOutput -Text $AnswerText -NoNewline;
        $Response = $Host.UI.ReadLine();
    }
    
    return $Selections | Where-Object { $_.Key -eq $Response }
}

class KeySelection {
    [String] $Key; [String] $Name; [ScriptBlock] $Function;

    KeySelection([System.Object[]]$Object) {
        $this.Key = $Object[0];
        $this.Name = $Object[1];
        $this.Function = $Object[2];
    }
    
    KeySelection($Key, $Name, $Function) {
        $this.Key = $Key;
        $this.Name = $Name
        $this.Function = $Function
    }

    Run() {
        $this.Function.Invoke()
    }
}

function PauseUser {
<#
    .SYNOPSIS
    Pauses the user, forcing them to press enter to continue
#>
    param( [string] $PauseText="&[yellow]Press '&[highlight]ENTER&[yellow]' to continue..." )

    # Ensure NoNewLine exists, unless specifically set to False

    HandleTextTypesOutput -Text $PauseText -NoNewline; $host.UI.ReadLine();
}