[CmdletBinding()]
Param(
    [string]$file,
    [array]$values,
    [switch]$strict,
    [switch]$help
)

$ErrorActionPreference = "Stop"

try
{
    if ($help)
    {
        Write-Output ''
        Write-Output 'USAGE: .\SetupIntegrationTests.ps1 -File "filename" -Values "param1=value1", "param2=value2" [-Strict]'
        Exit 0
    }

    $arguments = @()

    Write-Output "`nProcessing target file $file"

    $content = Get-Content -Raw -Path $file

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
    $values |% `
    {
        # Get last line and split to SHA and filename
        $split = @( $_ -Split '=', 2 )

        # Create summary item
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
        if ($argument -ne $null)
        {
            $content = $content -replace $_, $argument.Value
            Write-Output "`tReplaced $_"
        }
        else
        {
            $msg = "No value was specified for config variable '$_'"
            if ($strict)
            {
                throw $msg
            }
            else
            {
                Write-Output "`tWarning: $msg"
            }
        }
    }

    Write-Output "`nWriting updated content to $file"
    $content | Set-Content -Encoding UTF8 -Path $file -Force
    
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