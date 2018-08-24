#.SYNOPSIS
# Implements the Fisher-Yaters Shuffle algorithm.
#
#.DESCRIPTION
# Implements the Fisher-Yaters Shuffle algorithm.
# Based on the C# version posted by Matt Howells on StackOverflow.
#
#.EXAMPLE
# $Array = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
# $Rng = [Random]::new()
# Sort-Random $Rng $Array
#
#.LINK
# https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
# https://stackoverflow.com/a/110570/5339918
#
function Sort-Random {
    [CmdletBinding()]
    [Alias()]
    [OutputType([Array])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [Array] $InputObject,

        # Random Number Generator
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$False,
                   Position=1)]
        [Random] $Rng = [Random]::New()
    )

    Begin
    {
        $Collection = @()    # Copy of the input array.
    }
    Process
    {
        # Regular params will just be copied. Pipelined input will be accumulated.
        $Collection += $InputObject
    }
    End
    {
        $n = $Collection.Length
        while ($n -gt 1)
        {
            $k = $Rng.Next($n--)
            $Temp = $Collection[$n]
            $Collection[$n] = $Collection[$k]
            $Collection[$k] = $Temp
        }
        return $Collection
    }
}
