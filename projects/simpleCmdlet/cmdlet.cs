using System;
using System.Management.Automation;

/*
 * Simple Powershell Cmdlet
 *
 * VS Compilation
 * Visual Studio --> New Project -- C# Class Library
 * Class inherits from Cmdlet or PSCmdlet. Latter has more features.
 * Building will produce a DLL in bin/debug folder
 * Call Import-Module on path to Cmdlet.dll and use Get-Module to check if it loaded
 *
 * PS Terminal Compilation
 * C:\Windows\Microsoft.NET\Framework\v4*\csc.exe /t:library /reference:$([psobject].assembly.location) .\cmdlet.cs
 * Call Import-Module on path to Cmdlet.dll and use Get-Module to check if it loaded
 */

namespace GetName
{
    [Cmdlet(VerbsCommon.Get, "Name")]
    public class GetNameCommand : Cmdlet
    {
        [Parameter(Position = 1, Mandatory = true)]
        public string Name { get; set; }

        // This is run when the Cmdlet is called. Visual Studio complains that it doesn't exist.
        protected override void ProcessRecord()
        {
            Console.WriteLine("{0}", Name);
        }
    }
}
