class opnfv::foobar {
  if $::osfamily == 'Debian' {
    package { 'foobar':
      ensure => installed,
    }
  }
}
