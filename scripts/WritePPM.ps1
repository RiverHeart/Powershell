# poita.org
# Simplest Image Format - Portable Pixmap (PPM)

# TODO: Binary doesn't work

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Write-PPM example.ppm 32 32 (255,255,255) -Format binary
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Write-PPM
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Output file path
        [Parameter(Mandatory=$true,
                   Position=0)]
        [String[]] $Path,

        # Width in pixels
        [Parameter(Mandatory=$true,
                   Position=1)]
        [int] $Width,

        # Height in pixels
        [Parameter(Mandatory=$true,
                   Position=2)]
        [int] $Height,

        # Image data, 3 bytes per pixel (R, G, B)
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=3)]
        $RGB_Data,

        # Output Format. Default is Text
        [Parameter(Mandatory=$false)]
        [switch] $Binary
    )

    Begin
    {
        $sb      = [System.Text.StringBuilder]::new()
        $Encoder = [System.Text.Encoding]::Default
        $Format  = if ($Binary) { "P6" } else { "P3" }
    }
    Process
    {
        # Appending the whole array will introduce unneeded spaces.
        # Too avoid this, loop and append individually.
        foreach ($Pixel in $RGB_Data) {
            if ($Binary) { $Pixel = [char][byte]$Pixel }
            [void] $sb.Append($Pixel)
        }
    }
    End
    {
        Set-Content -Path $Path -Value "$Format`n$Width $Height`n255" # Header
        Add-Content -Path $Path -Value $sb.ToString()                 # Body
    }
}