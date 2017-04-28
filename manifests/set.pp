# == Define: nssm:set
#
# Define to configure Windows Service using 'nssm set'
#
# === Parameters
# [*create_user*]
#   Boolean to control whether the user should be created
#    If true, dicates $command format due to:
#      - service accounts need to be prefixed with a .\
#    If default of false:
#      - Do not prefix with .\ otherwise command wil fail
#
# [*service_interactive*]
#   Allow service to interact with desktop
#   Defaults to false
#

define nssm::set (
  $create_user         = false,
  $service_name        = $title,
  $service_user        = 'LocalSystem',
  $service_pass        = undef,
  $service_interactive = false,
  $app_parameters      = undef,
  $user_domain         = undef,
  $app_std_out         = "C:/windows/logs/${service_name}.log",
  $app_err_out         = "C:/windows/logs/${service_name}_error.log",
) {

  if $create_user {
    user { $service_user:
      ensure   => present,
      comment  => "User which runs ${service_name}",
      groups   => ['BUILTIN\Administrators', 'BUILTIN\Users'],
      password => $service_pass,
    }
  }


  if $user_domain {
    $service_user_final = "${user_domain}\\${service_user}"
  } else {
    $service_user_final = $service_user
  }

  if $service_interactive {
    $service_type = 'SERVICE_INTERACTIVE_PROCESS'
  } else {
    $service_type = 'SERVICE_WIN32_OWN_PROCESS'
  }

  $escaped_app_parameters = regsubst($app_parameters, '"', '""""""', 'G')
  $hsh_props = {
    'ObjectName'       => "${service_user_final} '${service_pass}'",
    'Type'             => $service_type,
    'AppParameters'    => $escaped_app_parameters,
    'AppStdout'        => $app_std_out,
    'AppStderr'        => $app_err_out,
    'AppRotateOnline'  => '1',
    'AppRotateFiles'   => '1',
    'AppRotateSeconds' => '86400',
    'AppRotateBytes'   => '104857600',
  }
  $prop_keys = keys($hsh_props)

  $nssm_cmd_params = @("END_NSSM_CMD_PARAMS"/$)
    [Console]::OutputEncoding     = [System.Text.Encoding]::Unicode;
    \$ErrorActionPreference       = "Stop";
    \$service_name                = "${service_name}";
    \$sp_redirect_standard_error  = "C:/windows/logs/puppet_nssm_" + \$service_name + "set_error.txt";
    \$sp_redirect_standard_output = "C:/windows/logs/puppet_nssm_" + \$service_name + "set.txt";
    \$sp_parms = @{};
    \$sp_parms.add("RedirectStandardError",\$sp_redirect_standard_error);
    \$sp_parms.add("RedirectStandardOutput",\$sp_redirect_standard_output);
    | END_NSSM_CMD_PARAMS

  $exec_cmd_set_nssm_prop = @(END_CMD_SET_NSSM_PROP)
    $arg_list = "set " + $service_name + " " + $prop_name + " " + $prop_val;
    Write-Output "Arg list: $arg_list";
    $sp_parms.Add("ArgumentList", $arg_list);;
    $cmd_result = Start-Process "nssm" @sp_parms -Wait -PassThru;
    | END_CMD_SET_NSSM_PROP

  $exec_cmd_get_nssm_prop = @(END_CMD_GET_NSSM_PROP)
    $arg_list = "get " + $service_name + " " + $prop_name;
    Write-Output "Arg list: $arg_list";
    $sp_parms.Add("ArgumentList", $arg_list);
    $cmd_result = Start-Process "nssm" @sp_parms -Wait -PassThru;
    | END_CMD_GET_NSSM_PROP

  $exec_cmd_compare_prop = @(END_EXEC_CMD_COMPARE_PROP)
    $cmp_val = $prop_val.replace("'", "").trimend(" ");
    While($cmp_val.contains('""')) {$cmp_val = $cmp_val.replace('""', '"');};
    While($std_out.contains('""')) {$std_out = $std_out.replace('""', '"');};
    Write-Output "Comparing ref value '$cmp_val' to output val '$std_out'.";
    If ($std_out -eq $cmp_val) { Exit 0; } Else { Exit 1; };
  | END_EXEC_CMD_COMPARE_PROP

  $exec_cmd_cleanup = @(END_EXEC_CMD_CLEANUP)
    If($cmd_result.exitcode -ne 0) {Throw;}
    $std_out = Get-Content $sp_redirect_standard_output -Encoding unicode;
    Write-Output "STDOUT: $std_out";
    If (Test-Path $sp_redirect_standard_error) {
      $std_err = Get-Content $sp_redirect_standard_error -Encoding unicode;
      Write-Output "STDERR: $std_err";
    };
    | END_EXEC_CMD_CLEANUP


  $prop_keys.each | $nssm_prop_name | {

    $exec_cmd_final = "\
${nssm_cmd_params}; \
\$prop_name = \"${nssm_prop_name}\"; \
\$prop_val  = \"${hsh_props[$nssm_prop_name]}\"; \
${exec_cmd_set_nssm_prop}; \
${exec_cmd_cleanup}"

    $exec_unless_final = "\
${nssm_cmd_params}; \
\$prop_name = \"${nssm_prop_name}\"; \
\$prop_val  = \"${hsh_props[$nssm_prop_name]}\"; \
${exec_cmd_get_nssm_prop}; \
${exec_cmd_cleanup}; \
${exec_cmd_compare_prop};
"
    exec { "set_nssm_prop_${nssm_prop_name}_for_svc_${service_name}":
      command   => $exec_cmd_final,
      unless    => $exec_unless_final,
      provider  => 'powershell',
      logoutput => true,
    }
  }

}
