##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Class: Ntp
#
# Add Ntp content passed through astute.yaml into ntp.conf depending on the role
#
# Suitable yaml content:
# <begin>
# opnfv:
#   ntp:
#     controller: |
#      line 1
#      line 2
#    compute: |
#      line 1
#      line 2
# <end>
#
#
#

class opnfv::ntp(
  $file='/etc/ntp.conf'
) {

  case $::operatingsystem {
        centos, redhat: {
          $service_name = 'ntpd'
        }
        debian, ubuntu: {
          $service_name = 'ntp'
        }
  }

  if $::fuel_settings['role'] {
    if ($::fuel_settings['opnfv'] and
    $::fuel_settings['opnfv']['ntp']) {
      case $::fuel_settings['role'] {
        /controller/: {
          if $::fuel_settings['opnfv']['ntp']['controller'] {
            $template = 'opnfv/ntp.conf.controller.erb'
            $file_content = $::fuel_settings['opnfv']['ntp']['controller']
          }
        }
        /compute/:    {
          if $::fuel_settings['opnfv']['ntp']['compute'] {
            $template = 'opnfv/ntp.conf.compute.erb'
            $file_content = $::fuel_settings['opnfv']['ntp']['compute']
          }
        }
      }
    }
  }

  if $file_content {
    package { 'ntp':
      ensure => installed,
    }

    file { $file:
      content => template($template),
      notify  => Service['ntp'],
    }

    service { 'ntp':
      ensure  => running,
      name    => $service_name,
      enable  => true,
      require => [ Package['ntp'], File[$file]]
    }
  }
}
