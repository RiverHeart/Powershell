<#
.SYNOPSIS
  Gets the average CPU load of a process over a duration (2 second default).
.DESCRIPTION
  Gets the average CPU load of a process over a duration (2 second default).

  $Process.cpu represents CPU time in seconds but can be accessed via $Process.TotalProcessorTime.TotalSeconds
  for clarity's sake.

  The following is the basic version of the script. Due to the lack of overhead, since we're working
  on a single process, its output should be closer to what you'll see in the Task Manager.

  $SystemTime1 = Get-Date
  $ProcessCPUTime1 = (ps -name $Name).cpu
  Start-Sleep $Seconds
  $SystemTime2 = Get-Date
  $ProcessCPUTime2 = (ps -name $Name).cpu

  # CPU Usage Formula Per Process
  $CPULoad = ($ProcessCPUTime2 - $ProcessCPUTime1) / ($SystemTime2 - $SystemTime1).TotalSeconds * 100 / $env:NUMBER_OF_PROCESSORS
  
  Adapted From: Frederic Chopin (http://stackoverflow.com/a/22675167) 

.EXAMPLE

psload
psload Notepad
psload Notepad -Seconds 10
psload -id 1010
#>
function Get-ProcessLoad
{
    [CmdletBinding(DefaultParameterSetName="name")]
    [Alias("psload")]
    Param
    (
        # Array of Process Names. Works on all processes by default.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName="name")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name = "*",

        # Array of Process ID's.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName="id")]
        [ValidateNotNullOrEmpty()]
        [int[]]$Id,

        # Duration in seconds. Shared by both parameter sets.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName="name")]
        [Parameter(ParameterSetName="id")]
        [ValidateNotNullOrEmpty()]
        [int]$Seconds = 2
    )

    if ($Id) {
        
        $SystemTime1 = Get-Date

        # The following casts the return of Get-Process as an array in case only one item is returned.
        # Select-Object is used to create a Value copy of Get-Process. Without Select-Object, we would have
        # a reference to the Process instead. The reference would point to the most up to date value of CPU
        # when we only desire the value at that instant.
        $ProcessList1 = @(Get-Process -id $Id | Select-Object Name, ID, CPU)
        
        Start-Sleep $Seconds
        
        $SystemTime2 = Get-Date
        $ProcessList2 = @(Get-Process -id $Id | Select-Object Name, ID, CPU)

        foreach ($Process1 in $ProcessList1) {
            foreach ($Process2 in $ProcessList2) {

                # Make sure we're getting data from the correct process.
                if ($Process1.id -eq $Process2.id) {
                    
                    $CPULoad = (($Process2.cpu - $Process1.cpu) /
                                ($SystemTime2 - $SystemTime1).TotalSeconds *
                                 100 / 
                                 $env:NUMBER_OF_PROCESSORS).toString("N")

                    Add-Member -InputObject $Process1 -NotePropertyName 'CPULoad' -NotePropertyValue $CPULoad
                    break; # Match found. Move to next Process.
                }
            }
        }

        return $ProcessList1

    } elseif ($Name) {

        $SystemTime1 = Get-Date

        # The following casts the return of Get-Process as an array in case only one item is returned.
        # Select-Object is used to create a Value copy of Get-Process. Without Select-Object, we would have
        # a reference to the Process instead. The reference would point to the most up to date value of CPU
        # when we only desire the value at that instant.
        $ProcessList1 = @(Get-Process -Name $Name | Select-Object Name, ID, CPU)
        
        Start-Sleep $Seconds
        
        $SystemTime2 = Get-Date
        $ProcessList2 = @(Get-Process -Name $Name | Select-Object Name, ID, CPU)

        foreach ($Process1 in $ProcessList1) {
            foreach ($Process2 in $ProcessList2) {

                # Make sure we're getting data from the correct process.
                if ($Process1.id -eq $Process2.id) {
                    
                    $CPULoad = (($Process2.cpu - $Process1.cpu) /
                                ($SystemTime2 - $SystemTime1).TotalSeconds *
                                 100 / 
                                 $env:NUMBER_OF_PROCESSORS).toString("N")
                    
                    Add-Member -InputObject $Process1 -NotePropertyName 'CPULoad' -NotePropertyValue $CPULoad
                    break; # Match found. Move to next process.
                }
            }
        }

        return $ProcessList1

    } else {
        throw "Unknown error. Please recheck parameters."
    }

    return @()

}
