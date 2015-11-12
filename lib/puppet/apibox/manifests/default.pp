Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin', '/usr/local/bin']
}

node default {

  stage { 'preinstall':
    before => Stage['main']
  }

  class {"nodejs_dev":
    user => $::puppet_user,
    install_dir => $::puppet_wdir,
    stage => "preinstall"
  }
  ->
  class {'nodejs_dev::install::mongodb':
    port => 27017,
    dbname => $::monogo_dbname,
    dbuser => $::monogo_dbuser,
    password => $::monogo_password,
    dbadmin => $::mongo_dbadmin,
    admin_password => $::mongo_admin_password,
    stage => "preinstall"
  }

  package { 'strongloop':
    ensure   => '>= 2.10.0',
    provider => 'npm',
  }

  package { 'loopback-connector-mongodb':
    ensure   => '>= 1.5.0',
    provider => 'npm',
    require => Package['strongloop'],
  }

  package { 'loopback-connector-rest':
    ensure   => '>= 1.10.1',
    provider => 'npm',
    require => Package['strongloop'],
  }

}
