# Requires -Version 5

# Summary: Converted Dan Water's audio intro to Powershell. Generates a simple wave file and plays the sound from it.
# Credit: Dan Water's "Intro to Audio Programming"
# Link: https://blogs.msdn.microsoft.com/dawate/2009/06/22/intro-to-audio-programming-part-1-how-audio-data-is-represented/
# Link: https://blogs.msdn.microsoft.com/dawate/2009/06/23/intro-to-audio-programming-part-2-demystifying-the-wav-format/
# Link: https://blogs.msdn.microsoft.com/dawate/2009/06/24/intro-to-audio-programming-part-3-synthesizing-simple-wave-audio-using-c/
# Link: https://blogs.msdn.microsoft.com/dawate/2009/06/25/intro-to-audio-programming-part-4-algorithms-for-different-sound-waves-in-c/
#
# Additional Reading Material
# Link: https://blogs.msdn.microsoft.com/larryosterman/2004/10/26/what-is-audio-on-a-pc-anyway/
# Link: https://blogs.msdn.microsoft.com/larryosterman/2004/10/28/whats-in-a-wav-file/
# Link: https://blogs.msdn.microsoft.com/larryosterman/2007/01/10/how-long-is-a-wav-file/
# Link: https://blogs.msdn.microsoft.com/larryosterman/2007/10/18/the-evolution-of-a-data-structure-the-waveformat/
# Link: https://blogs.msdn.microsoft.com/larryosterman/2011/03/09/how-do-people-keep-coming-up-with-this-stuff-mspaint-as-an-audio-track/

<#
.Synopsis
   Converts relative paths to full paths. C# methods often require full paths 
   and Resolve-Path will fail if the path doesn't exist.
.EXAMPLE
   Get-FullPath '~', 'test'
.EXAMPLE
   '~', '~\test' | Get-FullPath
#>
function Get-FullPath
{
    [CmdletBinding(DefaultParameterSetName="normal")]
    Param
    (
        [Parameter(ParameterSetName="normal",
                   Mandatory=$True,
                   Position=0)]
        [Parameter(ParameterSetName="pipeline",
                   ValueFromPipeline=$True)]
        [Array]$Path
    )

    begin {}
    
    # Pipeline values get processed sequentially. Arrays from regular input are not and require manual looping.
    process {
        if ($PSCmdlet.ParameterSetName -eq 'pipeline') {
            $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPsPath($Path)
        } else {
            foreach ($Item in $Path) {
                $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPsPath($Item)
            }
        }
    }
    end {}
}

class WaveHeader 
{
    [string] $GroupID = "RIFF"    # Resource Interchange File Format
    [uint32] $FileLength = 0      # Total file size in bytes, minus 8 for RIFF
    [string] $RiffType = "WAVE"   # Always WAVE
}

<#
  Defaults:
  Sample Rate: 44100 Hz
  Channels: Stereo
  Bit depth: 16-bit
#>
class WaveFormatChunk 
{
    [string] $ChunkID = "fmt "
    [uint32] $ChunkSize = 16        # Length of header in bytes.
    [uint16] $FormatTag = 1         # 1 (MC PCM)
    [uint16] $Channels = 2          # Number of channels
    [uint32] $SamplesPerSec = 44100 # Frequency in Hz
    [uint16] $BitsPerSample = 16
    
    # Sample frame size in bytes.
    [uint16] $BlockAlign = ($this.Channels * ($this.BitsPerSample / 8))
    
    # For estimating RAM allocation
    [uint32] $AvgBytesPerSec = $this.SamplesPerSec * $this.BlockAlign
}

<#
  Value ranges
  8-bit audio: -128 to 127      (see "2's Complement")
  16-bit audio: -32760 to 32760
  32-bit audio: -1.0f to 1.0f   (32 bit is a float.)
#>
class WaveDataChunk 
{
    [string] $ChunkID = "data"
    [uint32] $ChunkSize
    
    # Could be signed byte[], short[], or float[].
    [int16[]]$SampleData
}

enum WaveExampleType
{
    ExampleSineWave = 0
}

class WaveGenerator
{
    $Header = [WaveHeader]::new()
    $Format = [WaveFormatChunk]::new()
    $Data   = [WaveDataChunk]::new()

    WaveGenerator ([WaveExampleType]$Type)
    {
        switch ($Type)
        {
            ([WaveExampleType]::ExampleSineWave)
            {
                [uint32] $NumSamples = $this.Format.SamplesPerSec * $this.Format.Channels

                # Initialize array
                $this.Data.SampleData = New-Object int16[] $NumSamples

                [int] $Amplitude = 32760   # Max amp for 16 bit audio
                [double] $Freq = 440.0     # Concert A: 440

                # The "angle" sed in the function, adjusted for the number of channels.
                # This value is like the period of the wave.
                [double] $t = ([Math]::PI * 2 * $Freq) / ($NumSamples)
                
                for ($i = 0; $i -lt ($NumSamples-1); $i += 1)
                {
                    # Fill with a simple sine wave at max amplitude
                    for ($channel =0; $channel -lt ($this.Format.Channels-1); $channel += 1)
                    {
                        $this.Data.SampleData[$i + $channel] = [Convert]::ToInt16($Amplitude * [Math]::Sin($t * $i))
                    }
                }

                $this.Data.ChunkSize = [uint32]($this.Data.SampleData.Length * ($this.Format.BitsPerSample / 8))
                break
            }
            default { break }
        }
    }
    
    Save ([string]$Filepath)
    {
        # Create a file (it always overwrites)
        $FileStream = [System.IO.FileStream]::new($Filepath, [System.IO.FileMode]::Create)
    
        # Use BinaryWriter to write the bytes to the file
        $BinaryWriter = [System.IO.BinaryWriter]::new($FileStream)

        # Write the header
        $BinaryWriter.Write($this.Header.GroupID.ToCharArray())
        $BinaryWriter.Write($this.Header.FileLength)
        $BinaryWriter.Write($this.Header.RiffType.ToCharArray())

        # Write the format chunk
        $BinaryWriter.Write($this.Format.ChunkID.ToCharArray())
        $BinaryWriter.Write($this.Format.ChunkSize)
        $BinaryWriter.Write($this.Format.FormatTag)
        $BinaryWriter.Write($this.Format.Channels)
        $BinaryWriter.Write($this.Format.SamplesPerSec)
        $BinaryWriter.Write($this.Format.AvgBytesPerSec)
        $BinaryWriter.Write($this.Format.BlockAlign)
        $BinaryWriter.Write($this.Format.BitsPerSample)

        # Write the data chunk
        $BinaryWriter.Write($this.Data.ChunkID.ToCharArray())
        $BinaryWriter.Write($this.Data.ChunkSize)
        
        foreach ($DataPoint in $this.Data.SampleData)
        {    
            $BinaryWriter.Write($DataPoint)
        }

        $BinaryWriter.Seek(4, [System.IO.SeekOrigin]::Begin)
        [uint32] $Filesize = [uint32] $BinaryWriter.BaseStream.Length
        $BinaryWriter.Write($Filesize - 8)

        # Clean up
        $BinaryWriter.Close()
        $FileStream.Close()
    }
}

$filepath = Get-FullPath("~\test.wav")
$Wave = [WaveGenerator]::new([WaveExampleType]::ExampleSineWave)
$Wave.Save($filepath)

$SoundPlayer = [System.Media.SoundPlayer]::new($filepath)
$SoundPlayer.Play();

# TODO:
<#
class AppForm : System.Windows.Forms.Form 
{

}
#>
