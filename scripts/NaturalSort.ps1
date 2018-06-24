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

<#
 # FURTHER READING 
 # https://blog.codinghorror.com/sorting-for-humans-natural-sort-order/
 # http://www.davekoelle.com/alphanum.html
 #>

enum ChunkType { 
    Alphanumeric = 0
    Numeric = 1 
}

Class AlphanumComparator : System.Collections.IComparer 
{

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

    [int] Compare([Object] $x, [Object] $y)
    {
        $s1 = $x -as [String]
        $s2 = $y -as [String]

        if ($s1 -eq $null -or $s2 -eq $null)
        {
            return 0
        }

        $thisMarker = 0; $thisNumericChunk = 0
        $thatMarker = 0; $thatNumericChunk = 0

        while (($thisMarker -lt $s1.Length) -or ($thatMarker -lt $s2.Length))
        {
            if ($thisMarker -ge $s1.Length)
            {
                return -1
            }
            elseif ($thatMarker -ge $s2.Length)
            {
                return 1
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

            $result = 0

            # If both chunks contain numeric characters, sort them numerically
            if ([char]::IsDigit($thisChunk[0]) -and [char]::IsDigit($thatChunk[0]))
            {
                $thisNumericChunk = [Convert]::ToInt32($thisChunk.ToString())
                $thatNumericChunk = [Convert]::ToInt32($thatChunk.ToString())

                if ($thisNumericChunk -lt $thatNumericChunk)
                {
                    $result = -1
                }

                if ($thisNumericChunk -gt $thatNumericChunk)
                {
                    $result = 1
                }
            }
            else
            {
                $result = $thisChunk.ToString().CompareTo($thatChunk.ToString())
            }

            if ($result -ne 0)
            {
                return $result
            }
        }

        return 0
    }
}

$Example  = @("filename 1", "filename 10", "filename 2", "filename 20",
              1, "a", "1a", "a1", 200, 2, 10, 300, 200, 100, "1b", "a1b", "a1200", "a13", 3)
$Comparer = [AlphanumComparator]::new()
Measure-Command {
    [Array]::Sort($Example, $Comparer)
}

Write-Host "Natural Sort:"
$Example
