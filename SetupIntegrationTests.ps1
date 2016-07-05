[CmdletBinding()]
Param(
    [string]$File,
    [parameter(Mandatory=$true,ValueFromRemainingArguments=$true)][array]$Values,
    [switch]$Strict,
    [switch]$NoPrompt,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

try
{
    if ($Help)
    {
        Write-Output ''
        Write-Output 'USAGE: .\SetupIntegrationTests.ps1 -File "filename" -Values "param1=value1", "param2=value2" [-Strict] [-NoPrompt]'
        Exit 0
    }

    $arguments = @()

    Write-Output "`nProcessing target file $File"

    $content = Get-Content -Raw -Path $File

    $regex = [regex] '(?<variable>#{\S+})'
    $allmatches = $regex.Matches($content);
    $variables = $allmatches | Select-Object -ExpandProperty Value

    if ($variables.Count -le 0)
    {
        Write-Output "`nNo variables to replace!"
        Exit 0
    }

    Write-Output "Found $($variables.Count) variables to be replaced"
    $variables |% { Write-Output "`t$_" }

    Write-Output "`nProcessing arguments"
    $Values |% `
    {
        # Get last line and split to SHA and filename
        $split = @( $_ -Split '=', 2 )

        # Create argument object
        $argument = [PSCustomObject] `
        @{
            Name = $split[0]
            Value = $split[1]
        }

        # Add to sha summary
        $arguments += $argument
    }

    Write-Output "Found $($arguments.Count) arguments"
    $arguments |% { Write-Output "`t$($_.Name)" }

    Write-Output "`nReplacing variables"
    $variables |% `
    {
        $param = $_
        $paramName = $_.Trim('#', '{', '}')

        $argument = $arguments |? { $_.Name -eq $paramName }
        if ($argument -eq $null -and !$NoPrompt)
        {
            $value = Read-Host -Prompt "Enter value for $_"
        
            # Create argument object
            $argument = [PSCustomObject] `
            @{
                Name = $paramName
                Value = $value
            }

            $arguments += $argument
        }

        if ($argument -ne $null)
        {
            $content = $content -replace $_, $argument.Value
            Write-Output "`tReplaced $_"
        }
        else
        {
            $msg = "No value was specified for config variable '$_'"
            if ($Strict)
            {
                throw $msg
            }
            else
            {
                Write-Output "`tWarning: $msg"
            }
        }
    }

    Write-Output "`nWriting updated content to $File"
    $content | Set-Content -Encoding UTF8 -Path $File -Force
    
    Write-Output "`nAll Done!"

    Exit 0
}
catch
{
    Write-Output ''
    Write-Output ''
    Write-Output $_
    Exit 1   
}