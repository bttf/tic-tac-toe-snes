param($file)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function check_args() {
	if ($args.length -lt 1) { return $false }
	if ($args[0] -eq $null -or $args[0] -eq "") { return $false }
	return $true
}

function getLastWriteTime($file) {
	if ($file -eq $null -or $file -eq "") { return $false }
	$x = Get-Item $file
	return $x.LastWriteTime
}

function zsnesLoadROM($file) {
	if ($file -eq $null -or $file -eq "") { return $false }
	$path = Resolve-Path -Relative $file
	Invoke-Expression ".\zsnesw.exe $path"
	return $true
}

if ($MyInvocation.InvocationName -eq '.') { exit }

$old_time = getLastWriteTime($file)
while ($true) {
	$new_time = getLastWriteTime($file)
	if ($new_time -ne $old_time) {
		Write-Host "Detected changes to $file. (Re-)Starting ZSNES ..."
		Stop-Process -processname "zsnesw" | Out-Null
		zsnesLoadROM "$here\$file"
		$old_time = $new_time
	}
	Start-Sleep -s 1
}
