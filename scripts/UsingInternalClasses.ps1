# References: 
# https://learn-powershell.net/2015/08/07/invoking-private-static-methods-using-powershell/
# https://stackoverflow.com/questions/1259222/how-to-access-internal-class-using-reflection
# https://stackoverflow.com/questions/15652656/get-return-value-after-invoking-a-method-from-dll-using-reflection
# https://github.com/PowerShell/PowerShell/blob/a8627b83e5cea71c3576871eacad7f2b19826d53/src/System.Management.Automation/help/HelpCommentsParser.cs

$ExampleComment = @"
<#
.SYNOPSIS
    This was a triumph
#>
"@
$CommentLines = [Collections.Generic.List`1[String]]::new()
$InvokeArgs = @($ExampleComment, $CommentLines)

# GetMethod Filter
$BindingFlags = 'static','nonpublic','instance'

# GetMethod Filter: We need to specify overloaded methods by their parameters
$ParamTypes  = [Type]::GetTypeArray($InvokeArgs)
$ParamCount  = [System.Reflection.ParameterModifier]::new(2)

$HelpParser  = [psobject].Assembly.GetType('System.Management.Automation.HelpCommentsParser')
$CollectCommentText = $HelpParser.GetMethod('CollectCommentText', $BindingFlags, $null, $ParamTypes, $ParamCount)

# Extension methods aren't part of the class so null gets called first.
# TODO: Figure out return value
$CollectCommentText.Invoke($Null,$InvokeArgs)
$InvokeArgs

$CommentHelp = [System.Management.Automation.Language.CommentHelpInfo]::new()
$CommentHelp.Synopsis
$CommentHelp.Description
$CommentHelp.Examples
$CommentHelp