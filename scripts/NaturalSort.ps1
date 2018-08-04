# Requires -Version 5

<#
 # The Alphanum Algorithm is an improved sorting algorithm for strings
 # containing numbers.  Instead of sorting numbers in ASCII order like
 # a standard sort, this algorithm sorts numbers in numeric order.
 #
 # The Alphanum Algorithm is discussed at http://www.DaveKoelle.com
 #
 # Based on the Java implementation of Dave Koelle's Alphanum algorithm.
 # Contributed by Jonathan Ruckwood <jonathan.ruckwood@gmail.com>
 #
 # Adapted by Dominik Hurnaus <dominik.hurnaus@gmail.com> to
 #   - correctly sort words where one word starts with another word
 #   - have slightly better performance
 #
 # Powershell adaptation of C# implementation by Riverheart.
 #
 # Released under the MIT License - https://opensource.org/licenses/MIT
 #
 # Permission is hereby granted, free of charge, to any person obtaining
 # a copy of this software and associated documentation files (the "Software"),
 # to deal in the Software without restriction, including without limitation
 # the rights to use, copy, modify, merge, publish, distribute, sublicense,
 # and/or sell copies of the Software, and to permit persons to whom the
 # Software is furnished to do so, subject to the following conditions:
 #
 # The above copyright notice and this permission notice shall be included
 # in all copies or substantial portions of the Software.
 #
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 # IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 # DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 # OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
 # USE OR OTHER DEALINGS IN THE SOFTWARE.
 #
 #>

enum ChunkType { 
    Alphanumeric = 0
    Numeric = 1 
}

enum CompareResult {
    Second = -1
    Equal  =  0
    First  =  1
}

<#
 # The following is a Singleton implementation of the AlphanumComparer
 # The benefit is that you can call Sort-Natural without worrying about
 # instantiating an AlphanumComparer object or recreating an instance on
 # every call to Sort-Natural.
 #
 # An IComparer object implements the Compare method which is called
 # naturally by [Array]::Sort
 #
 # Reading material:
 # https://msdn.microsoft.com/en-us/library/system.collections.comparer.compare(v=vs.110).aspx
 #>
class AlphanumComparer : System.Collections.IComparer 
{

    static [AlphanumComparer] $Instance
    
    static [AlphanumComparer] GetInstance() 
    {
        if ([AlphanumComparer]::Instance -eq $null) 
        {
            [AlphanumComparer]::Instance = [AlphanumComparer]::new()
        }
        return [AlphanumComparer]::Instance 
    }

    [bool] InChunk([char] $char, [char] $otherChar) 
    {
        $type = [ChunkType]::Alphanumeric

        if ([char]::IsDigit($otherChar)) 
        {
            $type = [ChunkType]::Numeric
        }

        if (($type -eq [ChunkType]::Alphanumeric -and  [char]::IsDigit($char)) -or `
            ($type -eq [ChunkType]::Numeric      -and ![char]::IsDigit($char))) 
        {
            return $False
        }
        return $True
    }

    <#
     # Implements the Compare method from IComparer which looks at two objects and returns
     # a numeric value.
     #
     # -1: Second value is greater.
     #  0: Both values equal
     #  1: First value is greater.
     #>
    [int] Compare([Object] $x, [Object] $y)
    {
        $s1 = $x -as [String]
        $s2 = $y -as [String]

        if ($s1 -eq $null -or $s2 -eq $null)
        {
            return [CompareResult]::Equal
        }

        # Counters
        $thisMarker = 0; $thisNumericChunk = 0
        $thatMarker = 0; $thatNumericChunk = 0

        while (($thisMarker -lt $s1.Length) -or ($thatMarker -lt $s2.Length))
        {
            if ($thisMarker -ge $s1.Length)
            {
                return [CompareResult]::Second
            }
            elseif ($thatMarker -ge $s2.Length)
            {
                return [CompareResult]::First
            }
            [char] $thisChar = $s1[$thisMarker]
            [char] $thatChar = $s2[$thatMarker]

            $thisChunk = [System.Text.StringBuilder]::new()
            $thatChunk = [System.Text.StringBuilder]::new()

            while (($thisMarker -lt $s1.Length) -and `
                   ($thisChunk.Length -eq 0 -or $this.InChunk($thisChar, $thisChunk[0])))
            {
                $thisChunk.Append($thisChar) | Out-Null
                $thisMarker++

                if ($thisMarker -lt $s1.Length)
                {
                    $thisChar = $s1[$thisMarker]
                }
            }

            while (($thatMarker -lt $s2.Length) -and `
                    ($thatChunk.Length -eq 0 -or $this.InChunk($thatChar, $thatChunk[0])))
            {
                $thatChunk.Append($thatChar) | Out-Null
                $thatMarker++

                if ($thatMarker -lt $s2.Length)
                {
                    $thatChar = $s2[$thatMarker]
                }
            }

            $result = [CompareResult]::Equal

            # If both chunks contain numeric characters, sort them numerically
            if ([char]::IsDigit($thisChunk[0]) -and [char]::IsDigit($thatChunk[0]))
            {
                $thisNumericChunk = [Convert]::ToInt32($thisChunk.ToString())
                $thatNumericChunk = [Convert]::ToInt32($thatChunk.ToString())

                if ($thisNumericChunk -lt $thatNumericChunk)
                {
                    $result = [CompareResult]::Second
                }

                if ($thisNumericChunk -gt $thatNumericChunk)
                {
                    $result = [CompareResult]::First
                }
            }
            else
            {
                $result = $thisChunk.ToString().CompareTo($thatChunk.ToString())
            }

            if ($result -ne [CompareResult]::Equal)
            {
                return $result
            }
        }

        return [CompareResult]::Equal
    }
}

<#
.Synopsis
   Applies natural sort to an array.
.Description
   Uses the custom comparer [AlphanumComparer] to return a natural sort of an array.
.EXAMPLE
   PS C:\> Sort-Natural @('a',10,100,20)
   10
   20
   100
   a

   Regular usage of natural sort.
.EXAMPLE
   PS C:\> @('a',10,100,20) | Sort-Natural -Descending
   a
   100
   20
   10

   Natural Sort using pipeline and descending switch.
#>
function Sort-Natural
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([Array])]
    Param
    (
        # An array of values.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        $InputObject,

        [switch] $Descending
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
        [Array]::Sort($Collection, [AlphanumComparer]::GetInstance())
        if ($Descending) {
            [Array]::Reverse($Collection)
        }
        return $Collection
    }
}

$Example  = @("filename 1", "filename 10", "filename 2", "filename 20",
              1, "a", "1a", "a1", 200, 2, 10, 300, 200, 100, "1b", 
              "a1b", "a1200", "a13", 3)


Measure-Command {
    $Result = Sort-Natural $Example
}
Write-Host "Natural Sort:"
$Result
