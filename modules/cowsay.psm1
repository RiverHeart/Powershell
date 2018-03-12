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
#  | We read Knuth so you don't have to. -- Tim        |
#  | Peters (explaining what the Python developers do  |
#  | in their spare time)                              |
#   ---------------------------------------------------
#    	  \  ^__^
#    	   \ (oo)\______
#    	     (__)\      )\/
#    	        ||----w |
#    	        ||     ||
function cowsay() {
    [CmdletBinding(DefaultParameterSetName="normal")]
    Param(
        [Parameter(ParameterSetName="normal",Position = 0)]
        [Parameter(ParameterSetName="pipeline",ValueFromPipeline=$True)]
        [string] $Text = "Moo...",

        [Parameter(ParameterSetName="normal",
                   ValueFromPipeline=$False,
                   Position = 1)]
        [Parameter(ParameterSetName="pipeline",
                   ValueFromPipeline=$False,
                   Position=0)]
        [int] $LineMax = 50
    )

    begin {}
    process {
        # Splits words based on Whitespace Regex.
        $Words = $Text -split "\s"

        $sb = [System.Text.StringBuilder]::new()
        $LineLength = 0

        foreach ($Word in $Words) {
            $Word = $Word + ' '
            $LineLength += $Word.length

            # Add word if resulting length doesn't exceed max line size.
            if ($LineLength -lt $LineMax) {
                [void]$sb.Append("$word")
            } else {
                # Word did not fit in line. Put it on a new line. 
                # WARNING: Words longer than LineMax will overflow.
                $LineLength = $Word.length
                [void]$sb.Append("`n$Word")
            }
        }
    }
    end {

        # [char] x * [int] y repeats the character y times
        $TopBar    = ' ' + ('_' * ($LineMax + 1))
        $BottomBar = ' ' + ('-' * ($LineMax + 1))
        $Lines     = $sb.ToString() -split "`n"

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
}

#.SYNOPSIS
#
#  Given a ### delimited file, get strings, sort randomly and return one.
#  To run without specifying a filepath, your $profile should contain
#  $env:fortune = "/path/to/fortune/file"
#
#  Probably not the most performant thing in the world, especially on
#  large files, but better than nothing.
#
#.EXAMPLE
#
#  (fortune "fortunes.txt") | cowsay
function fortune() {
    [CmdletBinding(DefaultParameterSetName="normal")]
    Param(
        [Parameter(ParameterSetName="normal",Position=0)]
        [string] $Path = $env:fortune
    )
    
    if ([String]::IsNullOrEmpty($Path)) {
        throw "Fortune filepath not given."
    }

    return (Get-Content $Path -Delimiter "###" | Sort {Get-Random} | select -First 1).TrimEnd("###").Trim()
}
