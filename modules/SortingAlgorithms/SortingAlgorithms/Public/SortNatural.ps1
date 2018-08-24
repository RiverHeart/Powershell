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
    SecondGreater = -1
    Equal  =  0
    FirstGreater  =  1
}

<#
 # The following is a Singleton implementation of the AlphanumComparer
 # The benefit is that you can call Sort-Natural without worrying about
 # instantiating an AlphanumComparer object or recreating an instance on
 # every call to Sort-Natural.
 #
 # Variable & Method names have been updated to hopefully give a better 
 # idea of what is going on.
 #
 # An IComparer object implements the Compare method which is called
 # naturally by [Array]::Sort
 #
 #
 # Reading material:
 # http://www.davekoelle.com/alphanum.html
 # https://msdn.microsoft.com/en-us/library/system.collections.comparer.compare(v=vs.110).aspx
 #>
class AlphanumComparer : System.Collections.IComparer 
{

    static [AlphanumComparer] $Instance
    
    static [AlphanumComparer] GetInstance() 
    {
        if ([AlphanumComparer]::Instance -eq $null) { [AlphanumComparer]::Instance = [AlphanumComparer]::new() }
        
        return [AlphanumComparer]::Instance 
    }

    <#
     # Returns a boolean value whether the characters are of the same type (Alphabetical or Numeric).
     #
     # a and b | True
     # 1 and 2 | True
     # a and 1 | False
     #>
    [bool] OfSameType([char] $char, [char] $otherChar) 
    {
        if ([char]::IsDigit($otherChar)) { $type = [ChunkType]::Numeric      }
        else                             { $type = [ChunkType]::Alphanumeric }

        if (($type -eq [ChunkType]::Alphanumeric -and  [char]::IsDigit($char)) -or
            ($type -eq [ChunkType]::Numeric      -and ![char]::IsDigit($char))) 
        {
            return $False    # Character types don't match.
        }
        return $true    # Character types match
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

        # Can't compare nulls.
        if ($s1 -eq $null -or $s2 -eq $null) { return [CompareResult]::Equal }

        $s1Marker = 0; $s2Marker = 0              # Initialize Counters
        $s1NumericChunk = 0; $s2NumericChunk = 0  # Set Default Value for Numeric Chunks
        
        # Keep going till either string ends.
        while (($s1Marker -lt $s1.Length) -or ($s2Marker -lt $s2.Length))
        {
            # Return longest string
            if ($s1Marker -ge $s1.Length) { return [CompareResult]::SecondGreater }
            if ($s2Marker -ge $s2.Length) { return [CompareResult]::FirstGreater }

            # Get characters for comparison.
            [char] $s1Char = $s1[$s1Marker]
            [char] $s2Char = $s2[$s2Marker]

            $s1Chunk = [System.Text.StringBuilder]::new()
            $s2Chunk = [System.Text.StringBuilder]::new()

            # Until we reach the end of the string,
            # Add char to chunk if chunk is empty
            # or until we find a char that doesn't match
            # the first 
            while (($s1Marker -lt $s1.Length) -and
                   ($s1Chunk.Length -eq 0 -or $this.OfSameType($s1Char, $s1Chunk[0])))
            {
                $s1Chunk.Append($s1Char) | Out-Null
                $s1Marker++

                if ($s1Marker -lt $s1.Length) { $s1Char = $s1[$s1Marker] }
            }

            # Same story as before.
            while (($s2Marker -lt $s2.Length) -and `
                    ($s2Chunk.Length -eq 0 -or $this.OfSameType($s2Char, $s2Chunk[0])))
            {
                $s2Chunk.Append($s2Char) | Out-Null
                $s2Marker++

                if ($s2Marker -lt $s2.Length) { $s2Char = $s2[$s2Marker] }
            }

            # Now that both chunks are prepared, we need to compare them.
            # If both chunks are numeric, compare numerically. 
            # Otherwise, cast and compare them as strings.

            $result = [CompareResult]::Equal    # Default value.

            if ([char]::IsDigit($s1Chunk[0]) -and [char]::IsDigit($s2Chunk[0]))
            {
                $s1NumericChunk = [Convert]::ToInt32($s1Chunk.ToString())
                $s2NumericChunk = [Convert]::ToInt32($s2Chunk.ToString())

                if ($s1NumericChunk -lt $s2NumericChunk) { $result = [CompareResult]::SecondGreater }
                if ($s1NumericChunk -gt $s2NumericChunk) { $result = [CompareResult]::FirstGreater }
            }
            else { 
                # CompareTo returns the same values as our Compare method.
                $result = $s1Chunk.ToString().CompareTo($s2Chunk.ToString())
            }

            # If the chunks don't match, return the greater of the two.
            # Otherwise, keep processing chunks.
            if ($result -ne [CompareResult]::Equal) { return $result }
        }

        # We evaluated all the chunks and these strings are equal.
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