#.WARNING
# It's been a while since I've run this. You might need to fiddle around with some things to get it to work on your system.
#
#.SYNOPSIS
# Powershell script to setup environment variables for C/C++ compiling after installing Visual C++ Build Tools Technical Preview 2015
# Intended to be a simple replacement for C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\vcvars64.bat
#
# Remove-Item Env:\include
# Remove-Item Env:\lib

function Get-OSVersion () {
     return (Get-WmiObject Win32_OperatingSystem).Version.Split('.')[0]
}

function Get-OSArchitecture () {
    return (Get-WmiObject Win32_OperatingSystem).OSArchitecture
}

$VisualCPath = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC'

# Includes standard and extra libraries.
$WindowsKitPath = ''

if ((Get-OSVersion) -eq 10) {

    $WindowsKitPath = 'C:\Program Files (x86)\Windows Kits\10'

    if ((test-path $VisualCPath) -eq $false) {
        return "Missing: $VisualCPath"
    }

    if ((test-path $WindowsKitPath) -eq $false) {
        return "Missing: $WindowsKitPath"
    } else {
        $Versions = @()
        $Versions += Get-ChildItem "$WindowsKitPath\Lib" | Select -ExpandProperty Name
        $NewestVersion = $Versions[$Versions.length - 1]
        $LibraryPath = "$WindowsKitPath\lib\$NewestVersion"
    }
    
    # CL.exe will check this variable for paths to the header files
    $env:include = "$VisualCPath\include;" + "$WindowsKitPath\include\$NewestVersion\ucrt"
    
    # Library files are separated base on architecture. CL checks $env:lib for the right ones.
    switch (Get-OSArchitecture) {
        '64-bit' {
            write-host "Setting up for 64bit OS."
            $env:lib = "$VisualCPath\lib\amd64;" +
                       "$LibraryPath\um\x64;" +
                       "$LibraryPath\ucrt\x64"
        }
        '32-bit' {
            write-host "Setting up for 32bit OS."
            $env:lib = "$VisualCPath\lib;" +
                       "$LibraryPath\um\x86;" +
                       "$LibraryPath\ucrt\x86"          
        }
    }
    return
}

function CL-Wrapper {
    [CmdletBinding()]
    [Alias('cl')]
    param($Args)

    # Pass /nologo by default because Powershell errors on the output.
    & 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\cl.exe' /nologo $Args
}
