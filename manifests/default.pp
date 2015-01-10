Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin', '/usr/local/bin']
}

node default {

  stage { 'preinstall':
    before => Stage['main']
  }

  class {"nodejs_dev":
    user => $puppet_user,
    stage => "preinstall"
  }

  exec {"express vatrates":
    creates => "${puppet_wdir}/../vatrates",
    cwd     => "${puppet_wdir}/../",
    user    => $puppet_user
  }
  ->
  nodejs::npm { "${puppet_wdir}/../vatrates:strongloop":
    ensure  => present,
    version => "~2.10.0",
  }

}
