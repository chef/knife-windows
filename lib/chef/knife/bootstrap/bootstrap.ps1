function log($msg) {
  $timestamp = Get-Date -Format "[yyyy-MM-dd hh:mm:ss]"
  add-content "$($config['CHEF_PS_LOG'])" "$timestamp $msg"
}

function report_status($exitcode) {
  set-content "$($config['CHEF_PS_EXITCODE'])" "$exitcode"
}

function ps_exit() {
  Start-Sleep 1
  while (Test-Path "$($config['CHEF_PS_LOG'])") { Remove-Item "$($config['CHEF_PS_LOG'])" -Force -ErrorAction SilentlyContinue }
  exit 99
}

function cleanup() {
  Remove-Item "$($config['CHEF_LOCAL_MSI_PATH'])" -Force -ErrorAction SilentlyContinue
  Remove-Item "$($config['CHEF_CLIENT_MSI_LOG_PATH'])" -Force -ErrorAction SilentlyContinue
}

$cmd_input_variables = @("CHEF_PS_LOG", "CHEF_PS_EXITCODE", "CHEF_REMOTE_URL", "CHEF_LOCAL_MSI_PATH", "CHEF_http_proxy","CHEF_CLIENT_MSI_LOG_PATH","CHEF_ENVIRONMENT_OPTION","CHEF_BOOTSTRAP_DIRECTORY","CHEF_CUSTOM_INSTALL_COMMAND","CHEF_EXTRA_MSI_PARAMETERS")
$config = @{}
$cmd_input_variables | ForEach-Object {
	$config[$_] = (get-childitem env:$_ -ErrorAction SilentlyContinue).value
}
log "`nConfig loaded from environment:$($config | Out-String -Width 150)"

log "Removing bootstrap files left by potential earlier run"
cleanup

log "Setting up Webclient"
$webClient = new-object System.Net.WebClient;
if ($config['CHEF_http_proxy'] -ne '') {
  log "Configuring proxy $($config['CHEF_http_proxy']) in Webclient"
  $WebProxy = New-Object System.Net.WebProxy($config['CHEF_http_proxy'],$true)
  $WebClient.Proxy = $WebProxy
}

log "Starting download from $( $config['CHEF_REMOTE_URL'] ) to $( $config['CHEF_LOCAL_MSI_PATH'] )"
$webClient.DownloadFile($config['CHEF_REMOTE_URL'], $config['CHEF_LOCAL_MSI_PATH'] );

log "Download done. Checking local file."
if (!(Test-Path "$($config['CHEF_LOCAL_MSI_PATH'])")) {
  log "Download failed. Local MSI not found."
  report_status 3; ps_exit
}
$filesize = (Get-Item "$($config['CHEF_LOCAL_MSI_PATH'])").length
if ($filesize -eq 0) {
  log "DOWNLOAD FAILED - Filesize is 0."
  report_status 2; ps_exit
}
log "Download filesize is $filesize"

log "Starting Chef client install"
if ($config['CHEF_CUSTOM_INSTALL_COMMAND'] ) {
  log "Running custom install command $($config['CHEF_CUSTOM_INSTALL_COMMAND'])"
  $install_process = Start-Process -PassThru -Wait "$env:comspec" -ArgumentList "/v /e /c`"start /wait cmd /c %CHEF_CUSTOM_INSTALL_COMMAND% & exit !errorlevel!;`""
} else {
  log "msiexec.exe /qn /log `"$($config['CHEF_CLIENT_MSI_LOG_PATH'])`" /i `"$($config['CHEF_LOCAL_MSI_PATH'])`" $($config['CHEF_EXTRA_MSI_PARAMETERS'])"
  $install_process = Start-Process -PassThru -Wait msiexec.exe -ArgumentList "/qn /log `"$($config['CHEF_CLIENT_MSI_LOG_PATH'])`" /i `"$($config['CHEF_LOCAL_MSI_PATH'])`" $($config['CHEF_EXTRA_MSI_PARAMETERS'])"
}
$install_exitcode = $install_process.ExitCode

log "MSI install returned exit code $install_exitcode"
if ($install_exitcode -ne 0) { report_status $install_exitcode; ps_exit }

log "Cleaning up Chef bootstrap environment variables"
$cmd_input_variables | ForEach-Object {
  REG delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /F /V $_
}

log "Cleaning up Powershell logfile and starting first Chef run"
report_status 0
Start-Sleep 1
while (Test-Path "$($config['CHEF_PS_LOG'])") { Remove-Item "$($config['CHEF_PS_LOG'])" -Force -ErrorAction SilentlyContinue }

$chefrun_process = Start-Process -PassThru -Wait c:/opscode/chef/bin/chef-client.bat -ArgumentList "-c `"$($config['CHEF_BOOTSTRAP_DIRECTORY'])/client.rb`" -j `"$($config['CHEF_BOOTSTRAP_DIRECTORY'])/first-boot.json`" $($config['CHEF_ENVIRONMENT_OPTION']) -L `"$($config['CHEF_BOOTSTRAP_DIRECTORY'])/firstrun.log`""
$chefrun_exitcode = $chefrun_process.ExitCode

log "Chef run done. Cleaning up Chef firstrun logfile to get control back to bootstrap cmd"
While (Test-Path "$($config['CHEF_BOOTSTRAP_DIRECTORY'])/firstrun.log") { Remove-Item "$($config['CHEF_BOOTSTRAP_DIRECTORY'])/firstrun.log" -Force -ErrorAction SilentlyContinue }

log "First Chef run returned exit code $chefrun_exitcode. We're done."
if ($chefrun_exitcode -ne 0) {
  report_status $chefrun_exitcode; ps_exit
}

log "Cleaning up"
report_status 0
c:/windows/system32/schtasks.exe /F /delete /tn Chef_bootstrap
cleanup
ps_exit
