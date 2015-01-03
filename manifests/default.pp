Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin', '/usr/local/bin']
}

node "dev.node.js" {

  stage { 'preinstall':
    before => Stage['main']
  }

  class {"nodejs_dev":
    stage => "preinstall"
  }

  exec {"express vatrates":
    creates => "${puppet_wdir}/../vatrates",
    cwd     => "${puppet_wdir}/../",
    user    => "vagrant"
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:mongodb":
    ensure  => present,
    version => "~1.4.26",
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:monk":
    ensure  => present,
    version => "~0.9.1",
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:body-parser":
    ensure  => present,
    version => "~1.8.1",
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:cookie-parser":
    ensure  => present,
    version => "~1.3.3",
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:morgan":
    ensure  => present,
    version => "~1.3.0",
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:serve-favicon":
    ensure  => present,
    version => "~2.1.3",
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:debug":
    ensure  => present,
    version => "~2.0.0",
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:jade":
    ensure  => present,
    version => "~1.6.0",
  }
  ->
  file {
    "${puppet_wdir}/../vatrates/data":
      ensure => directory,
      group  => 'vagrant',
      owner  => 'vagrant',
      mode   => 0755,
  }

}
