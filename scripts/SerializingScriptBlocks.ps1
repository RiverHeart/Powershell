function ConvertTo-Base64 {
    Param($String)
    $bytes = [Text.Encoding]::UTF8.GetBytes($String)
    [Convert]::ToBase64String($bytes)
}

$foo = {
    write-host "foo"
}

$bar = {
    Param($Base64Func)
    Write-Host "bar"

    $Bytes      = [Convert]::FromBase64String($Base64Func)
    $SerialFunc = [Text.Encoding]::UTF8.GetString($Bytes)
    $FuncString = [System.Management.Automation.PSSerializer]::Deserialize($SerialFunc)
    $Func       = [ScriptBlock]::Create($FuncString)
    $Func.Invoke()
}

$SerialFunc = [System.Management.Automation.PSSerializer]::Serialize($foo)
$Base64Func = ConvertTo-Base64 $SerialFunc

Start-Job -ArgumentList $Base64Func -ScriptBlock $bar
Get-Job | Wait-Job
Get-Job | Receive-Job
