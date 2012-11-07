[xml]$transformFile = Get-Content $pipelineItemPath

$ns = @{ "deploy" = "http://github.com/kamsar/xdt-deploy" }

$rootPath = Select-Xml -Xml $transformFile -Namespace $ns -XPath "/configuration/deploy:TargetFile" | Select -ExpandProperty Node | Select -ExpandProperty InnerText

if([string]::IsNullOrEmpty($rootPath)) {
    Write-Warning "Unable to find a target file definition in $($pipelineItemPath)."
    Write-Warning "Make sure you have a deploy:TargetFile element in it with the correct namespace (http://github.com/kamsar/xdt-deploy), eg."
    Write-Warning @"

<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform" xmlns:deploy="http://github.com/kamsar/xdt-deploy">
	<deploy:TargetFile>Website\Web.config</deploy:TargetFile>
</configuration>
"@
    Write-Error "Aborting." -ErrorAction Stop
}

$rootPath = Join-Path $WorkingDirectory $rootPath | Resolve-Path

if($? -eq $false) {
    Write-Error "Path to transform did not exist, aborting." -ErrorAction Stop
}

$tempSourceName = "xdt-source-temp.xml"
$rootPathDirectory = [IO.Path]::GetDirectoryName($rootPath)
$tempSourcePath = Join-Path $rootPathDirectory $tempSourceName

Write-Host "Transforming " $rootPath.Path " using transform file " $pipelineItemPath

Rename-Item $rootPath $tempSourceName

if($? -eq $false) {
    Write-Error "Unable to create temp file for processing transform. Aborting." -ErrorAction Stop
}

$transformProcess = Start-Process -FilePath ".\System\Pipeline Providers\Support\ctt.exe" -ArgumentList ("s:`"$($tempSourcePath)`"", "t:`"$($pipelineItemPath)`"", "d:`"$($rootPath)`"") -NoNewWindow -Wait -PassThru

Remove-Item $tempSourcePath

if($transformProcess.ExitCode -ne 0) {
    Write-Error "A problem occurred applying XDT transformation. Aborting." -ErrorAction Stop
}

