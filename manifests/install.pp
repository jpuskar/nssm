# == Define: nssm:install
#
# Define to create a Windows Service using 'nssm install'
#
# === Parameters
# [*ensure*]
#   present: create the service
#    absent: delete the service
#   Defaults to undefined
#
# [*program*]
#   exe to run as a service
#   Defaults to undefined
#
# [*service_name*]
#   name of the service to display in services.msc

define nssm::install (
  $ensure       = undef,
  $program      = undef,
  $service_name = $title,
) {

  $nssm_cmd_params = @("END_NSSM_CMD_PARAMS"/$)
    \$ErrorActionPreference       = "Stop";
    \$program                     = "${program}";
    \$service_name                = "${service_name}";
    \$sp_redirect_standard_error  = "C:/windows/logs/puppet_nssm_" + \$service_name + "_error.txt";
    \$sp_redirect_standard_output = "C:/windows/logs/puppet_nssm_" + \$service_name + ".txt";
    \$sp_parms = @{};
    \$sp_parms.add("RedirectStandardError",\$sp_redirect_standard_error);
    \$sp_parms.add("RedirectStandardOutput",\$sp_redirect_standard_output);
    | END_NSSM_CMD_PARAMS

  $frag_install_cmd = @(END_FRAG_INSTALL_CMD)
     If ((Test-Path $program) -eq $false) {
       Throw "Path to file does not exist.";
     } Else {
       $sp_arglist = "install " + $service_name + " " + $program;
       $sp_parms.add("ArgumentList", $sp_arglist);
       $install_proc = Start-Process "nssm" @sp_parms -Wait -PassThru;
       If($install_proc.exitcode -ne 0) {Throw;}
    }
    | END_FRAG_INSTALL_CMD
  $install_cmd = "${nssm_cmd_params} ${frag_install_cmd}"

  $frag_check_service = @(END_FRAG_CHECK_SERVICE)
    $sp_arglist = "get " + $service_name + " Name";
    $sp_parms.add("ArgumentList", $sp_arglist);
    $check_proc = Start-Process "nssm" @sp_parms -Wait -PassThru;
    If($check_proc.exitcode -eq 0) {Exit 0;} Else {Exit 1;}
    | END_FRAG_CHECK_SERVICE
  $check_service = "${nssm_cmd_params} ${frag_check_service}"

  $frag_remove_cmd = @(END_FRAG_REMOVE_CMD)
     If ((Test-Path $program) -eq $false) {
       Throw "Path to file does not exist.";
     } Else {
       $sp_arglist = "remove " + $service_name + " confirm";
       $sp_parms.add("ArgumentList", $sp_arglist);
       $install_proc = Start-Process "nssm" @sp_parms -Wait -PassThru;
       If($install_proc.exitcode -ne 0) {Throw;}
    }
    | END_FRAG_REMOVE_CMD
  $remove_cmd = "${nssm_cmd_params} ${frag_remove_cmd}"

  if $ensure == present {
    exec { "install_nssm_service_${service_name}":
      command  => $install_cmd,
      unless   => $check_service,
      provider => 'powershell',
    }
  }

  if $ensure == absent {
    exec { 'remove_service_name':
      command  => $remove_cmd,
      onlyif   => $check_service,
      provider => 'powershell',
    }
  }

}
