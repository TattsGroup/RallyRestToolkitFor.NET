[CmdletBinding()]
Param(
    [switch]$force = $false
)

Get-ChildItem -Recurse *.template |% `
{
    $file = $_ -replace '.template', ''

    if ($force -or !(Test-Path($file)))
    {
        Write-Output "Creating $file from $_"
        Copy-Item $_ $file
    }
    else
    {
        Write-Output "File $file already exists, not replacing it"
    }
}