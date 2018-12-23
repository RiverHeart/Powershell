##################################################################################
#                            PowerShell Invaders                                 #
#                                                                                #
# Released under the Creative Commons                                            #
# Attribution-NonCommercial-ShareAlike 2.5 License                               #
#                                                                                #
# For the full license see : http://creativecommons.org/licenses/by-nc-sa/2.5/   #
#                                                                                #
# Authors:                                                                       #
#                                                                                #
#  Adrian Milliner - ps1@soapyfrog.com (aka millinad)                            #
#  Richy King      - richy@wiredupandfiredup.com                                 #
#  Nik Crabtree    - fido@prophecie.co.uk                                        #
#  Brian Long      - brian@blong.com                                             #
#                                                                                #
# Modified 2018 by Riverheart                                                    #
#                                                                                #
##################################################################################

# Note: Work in Progress

. "$PSSCriptRoot/SpaceInvadersBehaviour.ps1"

# Based on SpriteState
$InvaderImg     = @('/#\', '>X<')
$MotherShipImg  = @('[=O=]', '//o\\')
$BaseImg        = @('<@>', 'XXX')

$OrigBgColor    = $Host.UI.RawUI.BackgroundColor
$OrigFgColor    = $Host.UI.RawUI.ForegroundColor
$OrigTitle      = $Host.UI.RawUI.WindowTitle
$OrigCursorSize = $Host.UI.RawUI.CursorSize

$Settings = @{
    # Size of console used
    ScreenSize  = [System.Management.Automation.Host.Size]::new(60, 30)
    GameState   = [GameState]::Playing

    # Internal borders for movement
    LeftBorder  = [int]1
    RightBorder = [int]59
    TopBorder   = [int]1

    BaseLine    = [int]28    # Where the base lives
    InvaderLine = [int]28    # Where the Invaders fly
    MotherLine  = [int]28    # Where the mothership flies

    # Size of each wave alien wave
    WaveHeight = [int]5
    WaveWidth  = [int]5
}

$Scores = @{
    HiScores  = [int[]](3000,4000,5000,6000,7000,8000,6000,10000)
    LastScore = [int]0
    Credits   = [int]0
    Scores    = [int[]](0,0)    # Current player scores.
}

function main ()
{
    if ($Host.Name -match 'ISE')
    {
        Throw "Sorry, but ISE isn't supported. Use the regular console."
    }
    Clear-Host

    Draw-HUD -Score    $Scores.Scores[0] `
             -HiScores $Scores.HiScores[-1] `
             -Credits  $Scores.Credits

    # Game loop
    [Console]::TreatControlCAsInput = $true
    while ($Settings.GameState)
    {
        Check-ForCtrlC
        Write-Host "Duck"
        Start-Sleep 3
        #ProcessGame
    }
}

# This function relies on the following setting
# assigned true before the game loop.
# [Console]::TreatControlCAsInput
function Check-ForCtrlC
{
    if ([Console]::KeyAvailable)
    {
        $Key = [System.Console]::ReadKey($true)
        if ($Key.Modifiers -band [ConsoleModifiers]"control" -and ($Key.Key -eq "C"))
        {
            $Settings.GameState = [GameState]::Quiting
        }
    }
}

function Test-SpriteBehaviour
{
    $Invader = [Sprite]::new($x, $y, $InvaderImg, 'alive', 'white')
    $Invader.Draw(0,0)
    $Invader.Brain.ActiveState = $Function:Idle
}

function ProcessGame 
{
    $dx = 1
    $dy = 0
    $Level = 1

    $Wave = New-InvaderWave $Settings.InvaderLine $Settings.WaveHeight $Level
    foreach ($Invader in $Wave)
    {
        if ($Invader.State -eq [SpriteState]::Alive)
        {
            $Invader.Delta($dx, $dy)
        }
    }
}

enum GameState
{
    Quiting = 0
    Playing = 1
}

<#
.Synopsis
    SpriteState
#>
enum SpriteState
{
    Alive = 0
    Dead  = 0
}

<#
.SYNOPSIS
Text Based Sprite

.EXAMPLE
   $Invader = [Sprite]::new($x, $y, $InvaderImg, 'alive', 'white')
   $Invader.Draw(0,0)
   $Invader.Draw(20, 30)
   $Invader.Delta(5, 0)
#>
class Sprite
{
    [int] $x
    [int] $y
    [int] $xPrevious
    [int] $yPrevious
    [string[]] $Image
    [string] $Color
    [SpriteState] $State
    [FSM] $Brain

    Sprite([int]$x, [int] $y, $Image, $State='alive', $Color='White')
    {
        $this.x     = $x
        $this.y     = $y
        $this.Image = $Image
        $this.Color = $Color
        $this.State = $State
        $this.Brain = [FSM]::new($function:idle)
    }

    Draw([int] $x, [int] $y)
    {
        # Clear sprite from current position
        $this.Clear()

        # Render sprite at new position
        [Console]::SetCursorPosition($x, $y)
        Write-Host $this.Image[$this.State] -f $this.Color
        
        # Update sprite positioning
        $this.xPrevious = $this.x
        $this.yPrevious = $this.y
        $this.x = $x
        $this.y = $y
    }

    Move([int] $x, [int] $y)
    {
        $this.Draw($x, $y)
    }

    Delta([int] $dx, [int] $dy)
    {
        $dx += $this.x
        $dy += $this.y
        $this.Draw($dx, $dy)        
    }

    Clear()
    {
        if ($this.y -ge 0)
        {
            [Console]::SetCursorPosition($this.x, $this.y)
            [Console]::Write(' ' * $this.Image[$this.State].Length)
        }
    }
}

# Ref: http://haxeflixel.com/documentation/enemies-and-basic-ai/
class FSM
{
    [ScriptBlock] $ActiveState

    FSM($InitState=$null)
    {
        $this.ActiveState = $InitState
    }

    Update()
    {
        if ($this.ActiveState -ne $null)
        {
            $this.ActiveState()
        }
    }
}

# Build invader wave as an 8x5 block
# .Example
#    $Wave = New-InvaderWave $Settings.InvaderLine $Settings.WaveHeight $Level
#
function New-InvaderWave
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                   Position=0)]
        [int] $WaveLine,

        [Parameter(Mandatory=$True,
                   Position=1)]
        [int] $WaveHeight,

        [Parameter(Mandatory=$True,
                   Position=2)]
        [int] $Level
    )

    # Based on the level, build fleet lower. Cap at 4 though.
    if ($Level -gt 4) { $Level = 4 }

    $Offset   = $InvaderLine + $Level
    $Invaders = @()
    $Colors = 'red', 'blue', 'green', 'cyan', 'white'

    for ($Row = $WaveHeight - 1; $Row -ge 0; $Row--)
    {
        for ($Col = 0; $Col -lt 8; $Col++)
        {
            $x = 4 + $col * 4
            $y = $Offset + $Row * 2
            $Invaders += [Sprite]::new($x, $y, $InvaderImg, 'alive', $Colors[$Row])
        }
    }
    return $Invaders
}

function Draw-String
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   Position=0)]
        [string] $Text,

        [Parameter(Mandatory=$False,
                   Position=1)]
        [int] $Row = 0,

        [Parameter(Mandatory=$False,
                   Position=2)]
        [ValidateSet("Left", "Center", "Right")]
        [string] $Alignment,

        [Parameter(Mandatory=$False,
                   Position=3)]
        [int] $ScreenWidth = $Host.UI.RawUI.WindowSize.Width
    )

    switch ($Alignment) {
        "left"   { $x = 0                                  }
        "center" { $x = ($ScreenWidth - $Text.Length ) / 2 }
        "right"  { $x = $ScreenWidth - $Text.Length        }
    }
    [Console]::SetCursorPosition($x, $Row)
    [Console]::Write($Text)
}

function Reset-Host {
    $Host.UI.RawUI.BackgroundColor = $OrigBgColor
    $Host.UI.RawUI.ForegroundColor = $OrigFgColor
    $Host.UI.RawUI.WindowTitle     = $OrigTitle
    $Host.UI.RawUI.CursorSize      = $OrigCursor
}

function Draw-HUD
{
    Param( [int] $Score, [int] $HiScores, [int] $Credits )
 
    Draw-String "1UP: $($Score.ToString('00000#'))"  -Row 0 -Alignment Left
    Draw-String "HIGH: $($HiScores.ToString('00000#'))" -Row 0 -Alignment Center
    Draw-String "CREDITS: $($Credits.ToString('0#'))"  -Row 0 -Alignment Right
}

#
# RUN MAIN
#
main