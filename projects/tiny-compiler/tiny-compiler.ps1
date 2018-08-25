# https://github.com/mgechev/tiny-compiler/blob/master/tiny.js

# Builtin Alternative Returns PSToken Objects
# $Errors = $null
# [System.Management.Automation.PSParser]::Tokenize($string, [ref]$Errors)
function tokenize ([string]$String) {
    $string.split(' ') | Where-Object { $_ } | % { $_.Trim() }
}
$tokens = tokenize("sub 2 sum 1 3 4")


class parser {
    
    [int] $c = 0
    [string[]] $tokens
    
    parser ([string[]] $tokens) {
        $this.tokens = $tokens
    }

    [string] peek() { return $this.tokens[$this.c] }

    [string] consume() { return $this.tokens[$this.c++] }

    [hashtable] parseNum()
    { 
        $node = @{
            "value" = ([Convert]::ToInt32(( $this.consume() )));
            "type" = "Num"
        }
        return $node
    }
    
    [hashtable] parseOp()
    {
        $node = @{ 
            "value" = ($this.consume());
            "type" = "Op";
            "expr" = @()
        }
        while ($this.peek()) 
        {
            # Recursive descent starts here.
            $node.expr += $this.parseExpr()
        }
        return $node
    }

    [hashtable] parseExpr()
    {
        $val = $this.peek()
        if ([Regex]::IsMatch($val, "\d")) {
            return $this.parseNum()
        } else {
            return $this.parseOp()
        }
    }
}

$parser = [parser]::new($tokens)
$ast    = $parser.parseExpr()

# TODO: Split into simple and advanced version (which takes script block)
# QUESTION: Is Map recursive? Recursive foreach?
function Map-Object {
    [CmdletBinding()]
    [Alias("map")]
    param($InputObject)
    $InputObject | % {$accumulator = @() } {$accumulator += $_ * 2} { return $accumulator}
}
Map-Object @(1, 4, 9, 16)


#.SYNOPSIS
# Takes an array of values, manipulates the values, and totals them.
#
#.DESCRIPTION
# Details on how scriptblock works:
# While slightly difficult to grok, the script block passed to reduce must implement two parameters for the accumulator and current value which get passed inside process. When you act upon the value you're aiming to use the second parameter.
#
#.EXAMPLE
# @(1, 2, 3, 4) | Reduce-Object { param($a, $b) $a * $b }
#
#.EXAMPLE
# Reduce-Object -InputObject @(1, 2, 3, 4) { param($a, $b) $a * $b }
#
#.LINK
# https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/Reduce
# https://blogs.msdn.microsoft.com/sergey_babkins_blog/2014/10/30/calling-the-script-blocks-in-powershell/
# https://blogs.msdn.microsoft.com/sergey_babkins_blog/2015/01/02/powershell-script-blocks-are-not-closures/  
function Reduce-Object {
    [CmdletBinding()]
    [Alias("reduce")]
    [OutputType([Int])]
    param(
        # Meant to be passed in through pipeline.
        [Parameter(Mandatory=$True,
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$True)]
        [Int[]] $InputObject,
    
        # Position=0 because we assume pipeline usage by default.
        [Parameter(Mandatory=$True,
                    Position=0)]
        [ScriptBlock] $ScriptBlock,
    
        [Parameter(Mandatory=$False,
                    Position=1)]
        [Int] $InitialValue
    ) 
    
    begin {
        if ($InitialValue) { $Accumulator = $InitialValue }
    }
    
    process {
        foreach($Value in $InputObject) {
            if ($Accumulator) {
                # Execute script block given as param with values.
                $Accumulator = $ScriptBlock.InvokeReturnAsIs($Accumulator,  $Value)
            } else {
                # Contigency for no initial value given.
                $Accumulator = $Value
            }
        }
    }
    
    end {
        return $Accumulator
    }
}

<#
class Evaluator {
    
    $ast = @{}

    evaluator($ast) {
        $this.ast = $ast
    }

    evaluate() {
        $result = 0
        # Just return value of number
        if ($this.ast.type -eq "Num") { return $this.ast.val }

        # Perform operation and return value.
        foreach ($item in $this.ast.expr) {
            switch ($item) {
                'sum' { $item | reduce { param($a, $b) $a + $b }; Write-Host "sum" }
                'sub' { $item | reduce { param($a, $b) $a - $b }; Write-Host "sub" }
                'div' { $item | reduce { param($a, $b) $a / $b }; Write-Host "div" }
                'mul' { $item | reduce { param($a, $b) $a * $b }; Write-Host "mul" }
                Default {}
            }
        }
    }
}

$evaluator [evaluator]::new($ast)
$evaluator.evaluate()
#>

function evaluate {
    [CmdletBinding()]
    param($ast)

    # Just return value of number
    if ($ast.type -eq "Num") { return $ast.val }

    # Perform operation and return value.
    foreach ($item in $ast.expr) {
        write-host $item
        switch ($item) {
            'sum' { $item | reduce { param($a, $b) $a + $b }; Write-Host "sum" }
            'sub' { $item | reduce { param($a, $b) $a - $b }; Write-Host "sub" }
            'div' { $item | reduce { param($a, $b) $a / $b }; Write-Host "div" }
            'mul' { $item | reduce { param($a, $b) $a * $b }; Write-Host "mul" }
        }
    }
}

evaluate $ast
