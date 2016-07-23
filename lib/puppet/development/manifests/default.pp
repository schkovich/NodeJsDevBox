Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin', '/usr/local/bin']
}

node default {

  stage { 'preinstall':
    before => Stage['main']
  }

  class {"nodejs_dev":
    user => $::puppet_user,
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
    ensure   => '>= 6.0.1',
    provider => 'npm',
    require => Class['nodejs'],
  }

  package { 'loopback-connector-mongodb':
    ensure   => '>= 1.15.2',
    provider => 'npm',
    require => Package['strongloop'],
  }

  package { 'loopback-connector-rest':
    ensure   => '>= 2.0.0',
    provider => 'npm',
    require => Package['strongloop'],
  }

}
