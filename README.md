# nssm

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)

## Overview

This module contains a couple of defined types:
- `nssm::install`  install a service
- `nssm::set`  set the parameters for that service

#### Changelog
1.0.3
- Changed execs to use the heredoc format for readability.
- Added options to manage the following NSSM service properties:
  - AppStdout
  - AppStderr
- Fixed idempotency when using quotes or escaped characters.

#### Installing NSSM

This will obviously require NSSM to be installed.  If you need to install nssm, you may optionally declare the nssm class:

`include nssm`

Note, however, that the `nssm` class is simply declaring the [windows::nssm](https://forge.puppet.com/counsyl/windows#windowsnssm) class, which already does an excellent job of downloading and installing nssm, so understand `counsyl/windows` as a dependency to using my `nssm` class.

If you already have nssm installed, a default path to the nssm exe is assumed as `C:\Program Files\nssm-2.24\win64`.  This may be overridden if your PATH differs by supplying `nssm_path` as an attribute to the `nssm:install` and `nssm::set` defined types.

## Module Description

```
  # Install the service
  nssm::install { 'Jenkins_Agent':
    ensure       => present,
    program      => 'C:\Program Files\Java\jdk1.7.0_79\bin\java.exe',
    service_name => 'Jenkins_Agent',
  }
```

```
  # Service Management
  nssm::set { 'Jenkins_Agent':
    service_user        => 'LocalSystem',
    service_interactive => true,
    create_user         => false,
    app_parameters      => "-jar C:\swarm-jar-with-dependencies.jar -mode exclusive -executors 8 -username jenkins -password password -master http://localhost:8080 -labels windows -fsroot C:\opt\ci",
    require             => Nssm::Install['Jenkins_Agent'],
  }
```
