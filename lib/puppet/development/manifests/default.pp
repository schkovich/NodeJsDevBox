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
  class {'mongodb32xenial':
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
