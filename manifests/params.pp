# @api private
class postgresql::params inherits postgresql::globals {
  $version                    = $postgresql::globals::globals_version
  $postgis_version            = $postgresql::globals::globals_postgis_version
  $listen_addresses           = undef
  $port                       = 5432
  $log_line_prefix            = undef
  $ip_mask_deny_postgres_user = '0.0.0.0/0'
  $ip_mask_allow_all_users    = '127.0.0.1/32'
  $ipv4acls                   = []
  $ipv6acls                   = []
  $encoding                   = $postgresql::globals::encoding
  $locale                     = $postgresql::globals::locale
  $data_checksums             = $postgresql::globals::data_checksums
  $timezone                   = $postgresql::globals::timezone
  $service_ensure             = 'running'
  $service_enable             = true
  $service_manage             = true
  $service_restart_on_change  = true
  $service_provider           = $postgresql::globals::service_provider
  $manage_pg_hba_conf         = pick($manage_pg_hba_conf, true)
  $manage_pg_ident_conf       = pick($manage_pg_ident_conf, true)
  $manage_recovery_conf       = pick($manage_recovery_conf, false)
  $manage_selinux             = pick($manage_selinux, false)
  $package_ensure             = 'present'
  $module_workdir             = pick($module_workdir,'/tmp')
  $password_encryption        = undef
  $manage_datadir             = true
  $manage_logdir              = true
  $manage_xlogdir             = true

  # Amazon Linux's OS Family is 'Linux', operating system 'Amazon'.
  case $::osfamily {
    'RedHat', 'Linux': {
      $link_pg_config     = true
      $user               = pick($user, 'postgres')
      $group              = pick($group, 'postgres')
      $needs_initdb       = pick($needs_initdb, true)
      $version_parts      = split($version, '[.]')
      $package_version    = "${version_parts[0]}${version_parts[1]}"

      if $version == $postgresql::globals::default_version and $::operatingsystem != 'Amazon' {
        $client_package_name    = pick($client_package_name, 'postgresql')
        $server_package_name    = pick($server_package_name, 'postgresql-server')
        $contrib_package_name   = pick($contrib_package_name,'postgresql-contrib')
        $devel_package_name     = pick($devel_package_name, 'postgresql-devel')
        $java_package_name      = pick($java_package_name, 'postgresql-jdbc')
        $docs_package_name      = pick($docs_package_name, 'postgresql-docs')
        $plperl_package_name    = pick($plperl_package_name, 'postgresql-plperl')
        $plpython_package_name  = pick($plpython_package_name, 'postgresql-plpython')
        $service_name           = pick($service_name, 'postgresql')
        $bindir                 = pick($bindir, '/usr/bin')
        $datadir                = $::operatingsystem ? {
          'Amazon' => pick($datadir, "/var/lib/pgsql${package_version}/data"),
          default  => pick($datadir, '/var/lib/pgsql/data'),
        }
        $confdir                = pick($confdir, $datadir)
      } else {
        $client_package_name    = pick($client_package_name, "postgresql${package_version}")
        $server_package_name    = pick($server_package_name, "postgresql${package_version}-server")
        $contrib_package_name   = pick($contrib_package_name,"postgresql${package_version}-contrib")
        $devel_package_name     = pick($devel_package_name, "postgresql${package_version}-devel")
        $java_package_name      = pick($java_package_name, "postgresql${package_version}-jdbc")
        $docs_package_name      = pick($docs_package_name, "postgresql${package_version}-docs")
        $plperl_package_name    = pick($plperl_package_name, "postgresql${package_version}-plperl")
        $plpython_package_name  = pick($plpython_package_name, "postgresql${package_version}-plpython")
        $service_name           = $::operatingsystem ? {
          'Amazon' => pick($service_name, "postgresql${version_parts[0]}${version_parts[1]}"),
          default  => pick($service_name, "postgresql-${version}"),
        }
        $bindir                 = $::operatingsystem ? {
          'Amazon' => pick($bindir, '/usr/bin'),
          default  => pick($bindir, "/usr/pgsql-${version}/bin"),
        }
        $datadir                = $::operatingsystem ? {
          'Amazon' => pick($datadir, "/var/lib/pgsql${package_version}/data"),
          default  => pick($datadir, "/var/lib/pgsql/${version}/data"),
        }
        $confdir                = pick($confdir, $datadir)
      }

      case $::operatingsystem {
        'Amazon': {
          $service_reload = "service ${service_name} reload"
          $service_status = "service ${service_name} status"
        }

        # RHEL 5 uses SysV init, RHEL 6 uses upstart.  RHEL 7 and 8 both use systemd.
        'RedHat', 'CentOS', 'Scientific', 'OracleLinux': {
          if $::operatingsystemrelease =~ /^[78].*/ {
            $service_reload = "systemctl reload ${service_name}"
            $service_status = "systemctl status ${service_name}"
          } else {
            $service_reload = "service ${service_name} reload"
            $service_status = "service ${service_name} status"
          }
        }

        # Default will catch Fedora which uses systemd
        default: {
          $service_reload = "systemctl reload ${service_name}"
          $service_status = "systemctl status ${service_name}"
        }
      }

      $psql_path           = pick($psql_path, "${bindir}/psql")

      $perl_package_name   = pick($perl_package_name, 'perl-DBD-Pg')
      $python_package_name = pick($python_package_name, 'python-psycopg2')

      if $postgresql::globals::postgis_package_name {
        $postgis_package_name = $postgresql::globals::postgis_package_name
      } elsif $::operatingsystemrelease =~ /^5\./ {
        $postgis_package_name = 'postgis'
      } elsif $postgis_version and versioncmp($postgis_version, '2') < 0 {
        $postgis_package_name = "postgis${package_version}"
      } else {
        $postgis_package_name = "postgis2_${package_version}"
      }
    }

    'Archlinux': {
      $link_pg_config     = true
      $needs_initdb       = pick($needs_initdb, true)
      $user               = pick($user, 'postgres')
      $group              = pick($group, 'postgres')

      # Archlinux doesn't have a client-package but has a libs package which
      # pulls in postgresql server
      $client_package_name    = pick($client_package_name, 'postgresql')
      $server_package_name    = pick($server_package_name, 'postgresql-libs')
      $java_package_name      = pick($java_package_name, 'postgresql-jdbc')
      # Archlinux doesn't have develop packages
      $devel_package_name     = pick($devel_package_name, 'postgresql-devel')
      # Archlinux does have postgresql-contrib but it isn't maintained
      $contrib_package_name   = pick($contrib_package_name,'undef')
      # Archlinux postgresql package provides plperl
      $plperl_package_name    = pick($plperl_package_name, 'undef')
      $plpython_package_name  = pick($plpython_package_name, 'undef')
      $service_name           = pick($service_name, 'postgresql')
      $bindir                 = pick($bindir, '/usr/bin')
      $datadir                = pick($datadir, '/var/lib/postgres/data')
      $confdir                = pick($confdir, $datadir)
      $psql_path              = pick($psql_path, "${bindir}/psql")

      $service_status         = $service_status
      $service_reload         = "systemctl reload ${service_name}"
      $python_package_name    = pick($python_package_name, 'python-psycopg2')
      # Archlinux does not have a perl::DBD::Pg package
      $perl_package_name      = pick($perl_package_name, 'undef')
    }

    'Debian': {
      $link_pg_config     = false
      $user               = pick($user, 'postgres')
      $group              = pick($group, 'postgres')

      if $postgresql::globals::manage_package_repo == true {
        $needs_initdb = pick($needs_initdb, true)
        $service_name = pick($service_name, 'postgresql')
      } else {
        $needs_initdb = pick($needs_initdb, false)
        $service_name = $::operatingsystem ? {
          'Debian' => pick($service_name, 'postgresql'),
          'Ubuntu' => $::lsbmajdistrelease ? {
            /^10/ => pick($service_name, "postgresql-${version}"),
            default => pick($service_name, 'postgresql'),
          },
          default => undef
        }
      }

      $client_package_name    = pick($client_package_name, "postgresql-client-${version}")
      $server_package_name    = pick($server_package_name, "postgresql-${version}")
      $contrib_package_name   = pick($contrib_package_name, "postgresql-contrib-${version}")
      if $postgis_version and versioncmp($postgis_version, '2') < 0 {
        $postgis_package_name = pick($postgis_package_name, "postgresql-${version}-postgis")
      } else {
        $postgis_package_name = pick($postgis_package_name, "postgresql-${version}-postgis-${postgis_version}")
      }
      $devel_package_name     = pick($devel_package_name, 'libpq-dev')
      $java_package_name = $::operatingsystem ? {
        'Debian' => $::operatingsystemrelease ? {
          /^6/    => pick($java_package_name, 'libpg-java'),
          default => pick($java_package_name, 'libpostgresql-jdbc-java'),
        },
      default  => pick($java_package_name, 'libpostgresql-jdbc-java'),
      }
      $perl_package_name      = pick($perl_package_name, 'libdbd-pg-perl')
      $plperl_package_name    = pick($plperl_package_name, "postgresql-plperl-${version}")
      $plpython_package_name  = pick($plpython_package_name, "postgresql-plpython-${version}")
      $python_package_name    = pick($python_package_name, 'python-psycopg2')

      $bindir                 = pick($bindir, "/usr/lib/postgresql/${version}/bin")
      $datadir                = pick($datadir, "/var/lib/postgresql/${version}/main")
      $confdir                = pick($confdir, "/etc/postgresql/${version}/main")
      if $::operatingsystem == 'Debian' and versioncmp($::operatingsystemrelease, '8.0') >= 0 {
        # Jessie uses systemd
        $service_status = pick($service_status, "/usr/sbin/service ${service_name}@*-main status")
      } elsif $::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '15.04') >= 0 {
        # Ubuntu releases since vivid use systemd
        $service_status = pick($service_status, "/usr/sbin/service ${service_name} status")
      } else {
        $service_status = pick($service_status, "/etc/init.d/${service_name} status | /bin/egrep -q 'Running clusters: .+|online'")
      }
      $service_reload         = "service ${service_name} reload"
      $psql_path              = pick($psql_path, '/usr/bin/psql')
    }

    'Gentoo': {
      $user                = pick($user, 'postgres')
      $group               = pick($group, 'postgres')

      $client_package_name  = pick($client_package_name, 'UNSET')
      $server_package_name  = pick($server_package_name, 'postgresql')
      $contrib_package_name = pick_default($contrib_package_name, undef)
      $devel_package_name   = pick_default($devel_package_name, undef)
      $java_package_name    = pick($java_package_name, 'jdbc-postgresql')
      $perl_package_name    = pick($perl_package_name, 'DBD-Pg')
      $plperl_package_name  = undef
      $python_package_name  = pick($python_package_name, 'psycopg')

      $service_name         = pick($service_name, "postgresql-${version}")
      $bindir               = pick($bindir, "/usr/lib/postgresql-${version}/bin")
      $datadir              = pick($datadir, "/var/lib/postgresql/${version}_data")
      $confdir              = pick($confdir, "/etc/postgresql-${version}")
      $service_status       = pick($service_status, "systemctl status ${service_name}")
      $service_reload       = "systemctl reload ${service_name}"
      $psql_path            = pick($psql_path, "${bindir}/psql")

      $needs_initdb         = pick($needs_initdb, true)
    }

    'FreeBSD': {
      case $version {
        '94', '95': {
          $user                 = pick($user, 'pgsql')
          $group                = pick($group, 'pgsql')
          $datadir              = pick($datadir, '/usr/local/pgsql/data')
        }
        default: {
          $user                 = pick($user, 'postgres')
          $group                = pick($group, 'postgres')
          $datadir              = pick($datadir, "/var/db/postgres/data${version}")
        }
      }

      $link_pg_config       = true
      $client_package_name  = pick($client_package_name, "databases/postgresql${version}-client")
      $server_package_name  = pick($server_package_name, "databases/postgresql${version}-server")
      $contrib_package_name = pick($contrib_package_name, "databases/postgresql${version}-contrib")
      $devel_package_name   = pick($devel_package_name, 'databases/postgresql-libpqxx3')
      $java_package_name    = pick($java_package_name, 'databases/postgresql-jdbc')
      $perl_package_name    = pick($plperl_package_name, 'databases/p5-DBD-Pg')
      $plperl_package_name  = pick($plperl_package_name, "databases/postgresql${version}-plperl")
      $python_package_name  = pick($python_package_name, 'databases/py-psycopg2')

      $service_name         = pick($service_name, 'postgresql')
      $bindir               = pick($bindir, '/usr/local/bin')
      $confdir              = pick($confdir, $datadir)
      $service_status       = pick($service_status, "/usr/local/etc/rc.d/${service_name} onestatus")
      $service_reload       = "service ${service_name} reload"
      $psql_path            = pick($psql_path, "${bindir}/psql")

      $needs_initdb         = pick($needs_initdb, true)
    }

    'OpenBSD': {
      $user                = pick($user, '_postgresql')
      $group               = pick($group, '_postgresql')

      $client_package_name  = pick($client_package_name, 'postgresql-client')
      $server_package_name  = pick($server_package_name, 'postgresql-server')
      $contrib_package_name = pick($contrib_package_name, 'postgresql-contrib')
      $devel_package_name   = pick($devel_package_name, 'postgresql-client')
      $java_package_name    = pick($java_package_name, 'postgresql-jdbc')
      $perl_package_name    = pick($perl_package_name, 'databases/p5-DBD-Pg')
      $plperl_package_name  = undef
      $python_package_name  = pick($python_package_name, 'py-psycopg2')

      $service_name         = pick($service_name, 'postgresql')
      $bindir               = pick($bindir, '/usr/local/bin')
      $datadir              = pick($datadir, '/var/postgresql/data')
      $confdir              = pick($confdir, $datadir)
      $service_status       = pick($service_status, "/etc/rc.d/${service_name} check")
      $service_reload       = "/etc/rc.d/${service_name} reload"
      $psql_path            = pick($psql_path, "${bindir}/psql")

      $needs_initdb         = pick($needs_initdb, true)
    }

    'Suse': {
      $link_pg_config       = true
      $user                 = pick($user, 'postgres')
      $group                = pick($group, 'postgres')

      $client_package_name  = pick($client_package_name, "postgresql${version}")
      $server_package_name  = pick($server_package_name, "postgresql${version}-server")
      $contrib_package_name = pick($contrib_package_name, "postgresql${version}-contrib")
      $devel_package_name   = pick($devel_package_name, "postgresql${version}-devel")
      $java_package_name    = pick($java_package_name, "postgresql${version}-jdbc")
      $perl_package_name    = pick($plperl_package_name, 'perl-DBD-Pg')
      $plperl_package_name  = pick($plperl_package_name, "postgresql${version}-plperl")
      $python_package_name  = pick($python_package_name, 'python-psycopg2')

      $service_name         = pick($service_name, 'postgresql')
      $bindir               = pick($bindir, "/usr/lib/postgresql${version}/bin")
      $datadir              = pick($datadir, '/var/lib/pgsql/data')
      $confdir              = pick($confdir, $datadir)
      if $::operatingsystem == 'SLES' and versioncmp($::operatingsystemrelease, '11.4') <= 0 {
        $service_status     = pick($service_status, "/etc/init.d/${service_name} status")
        $service_reload     = "/etc/init.d/${service_name} reload"
      } else {
        $service_status     = pick($service_status, "systemctl status ${service_name}")
        $service_reload     = "systemctl reload ${service_name}"
      }
      $psql_path            = pick($psql_path, "${bindir}/psql")

      $needs_initdb         = pick($needs_initdb, true)
    }

    default: {
      $link_pg_config       = true
      $psql_path            = pick($psql_path, "${bindir}/psql")

      # Since we can't determine defaults on our own, we rely on users setting
      # parameters with the postgresql::globals class. Here we are checking
      # that the mandatory minimum is set for the module to operate.
      $err_prefix = "Module ${module_name} does not provide defaults for osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}; please specify a value for ${module_name}::globals::"
      if ($needs_initdb == undef) { fail("${err_prefix}needs_initdb") }
      if ($service_name == undef) { fail("${err_prefix}service_name") }
      if ($client_package_name == undef) { fail("${err_prefix}client_package_name") }
      if ($server_package_name == undef) { fail("${err_prefix}server_package_name") }
      if ($bindir == undef) { fail("${err_prefix}bindir") }
      if ($datadir == undef) { fail("${err_prefix}datadir") }
      if ($confdir == undef) { fail("${err_prefix}confdir") }
    }
  }

  if($data_checksums and versioncmp($version, '9.3') < 0) {
    fail('data_checksums require version 9.3 or greater')
  }

  $validcon_script_path = pick($validcon_script_path, '/usr/local/bin/validate_postgresql_connection.sh')
  $initdb_path          = pick($initdb_path, "${bindir}/initdb")
  $pg_hba_conf_path     = pick($pg_hba_conf_path, "${confdir}/pg_hba.conf")
  $pg_hba_conf_defaults = pick($pg_hba_conf_defaults, true)
  $pg_ident_conf_path   = pick($pg_ident_conf_path, "${confdir}/pg_ident.conf")
  $postgresql_conf_path = pick($postgresql_conf_path, "${confdir}/postgresql.conf")
  $recovery_conf_path   = pick($recovery_conf_path, "${datadir}/recovery.conf")
  $default_database     = pick($default_database, 'postgres')
}
