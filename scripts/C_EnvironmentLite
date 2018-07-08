<#
 #  .SYNOPSIS
 #  Ever wish Windows had a command line option for C compilation like Unix does?
 #  You may be surprised to learn it does, but Visual Studio normally hides the details of it.
 #  This script sets up system paths for C development similar to what vcvars64.bat does.
 #  If you want x86 support, replace amd64/x64 with x86.
 #
 #  .TESTED
 #  Successfully Tested on Windows 10 (7/7/18)
 #
 #  .REQUIREMENTS
 #  Run after installing Visual C++ Build Tools Technical Preview 2015
 #  Alternatively if you have Visual Studio installed, these files may already be available.
 #
 #  .LINK
 #  https://blogs.msdn.microsoft.com/vcblog/2015/03/03/introducing-the-universal-crt/
 #
 #>

# Cleanup
$env:include -and (Remove-Item Env:\include)
$env:lib     -and (Remove-Item Env:\lib)


function main() {

    $CPath       = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC'
    $KitPath     = 'C:\Program Files (x86)\Windows Kits\10'    # Includes standard and extra libraries.
    $LibraryPath = ''

    if (Test-Path $KitPath) {
        $NewestVersion = Get-ChildItem "$KitPath\Lib" | Select -Last 1
        $LibraryPath = "$KitPath\lib\$NewestVersion"
    }
    
    # CL.exe will check this variable for paths to the header files
    $env:include = "$CPath\include;" +
                   "$KitPath\include\$NewestVersion\ucrt"
    
    # Library files are separated base on architecture. CL checks $env:lib for the right ones.
    $env:lib = "$CPath\lib\amd64;" +
               "$LibraryPath\um\x64;" +
               "$LibraryPath\ucrt\x64"
}

function CL-Wrapper {
    [CmdletBinding()]
    [Alias('cl')]
    param($Args)

    # Pass /nologo by default because Powershell errors on the output.
    & 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\amd64\cl.exe' /nologo $Args
}

#
# Start
#

main
