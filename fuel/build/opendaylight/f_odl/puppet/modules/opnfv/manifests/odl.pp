class opnfv::odl {
  if $::osfamily == 'Debian' {


    case $::fuel_settings['role'] {
      /controller/: {
        package { 'odl':
          ensure => installed,
        }
      }
    }
  }
}
