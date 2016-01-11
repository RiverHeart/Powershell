#.SYNOPSIS
#
#  Tiny powershell script inspired by the Unix program Cowsay, written by Tony Monroe.
#
#.EXAMPLE
#
#  $Text = "We read Knuth so you don't have to. -- Tim Peters (explaining what the Python developers do in their spare time)"
#
#  cowsay $Text
#
#   ___________________________________________________
#  | We read Knuth so you don't have to. -- Tim       |
#  | Peters (explaining what the Python developers do  |
#  | in their spare time)                              |
#   ---------------------------------------------------
#    	  \  ^__^
#    	   \ (oo)\______
#    	     (__)\      )\/
#    	        ||----w |
#    	        ||     ||
function cowsay() {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [string] $Text = "Moo...",
        [Parameter(ValueFromPipeline = $true, Position = 1)]
        [int] $LineMax = 50
    )

    # Splits wrods based on Whitespace Regex.
    $Words = $Text -split "\s"

    # Create an array with an empty string. Necessary to use "+=" the first time.
    $Lines = @('')
    $i = 0

    foreach ($Word in $Words) {
        $Word = $Word + ' '
        $NewLength = ($Lines[$i].length + $Word.length)

        # Add word if resulting length doesn't exceed max line size.
        if ($NewLength -lt $LineMax) {
            $Lines[$i] += $Word
        } else {
            # Word did not fit in line. Add word to next line.
            $Lines += $Word
            ++$i
        }
    }

    # [char] x * [int] y repeats the character y times
    $TopBar    = ' ' + ('_' * ($LineMax + 1))
    $BottomBar = ' ' + ('-' * ($LineMax + 1))

    write-host $TopBar
    foreach ($Line in $Lines) {
        $Line = $Line.padright($LineMax - 1)
        write-host "| $Line |"
    }
    write-host $BottomBar -NoNewLine

    write-host "
    `t\  ^__^
    `t \ (oo)\______
    `t   (__)\      )\/
    `t      ||----w |
    `t      ||     ||"
}
