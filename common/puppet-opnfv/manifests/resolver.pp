##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Class: opnfv::resolver
#
# Add resolver content passed through astute.yaml into resolv.conf
# depending on the role
#
# Suitable yaml content:
# <begin>
# opnfv:
#  dns:
#    compute:
#    - 100.100.100.2
#    - 100.100.100.3
#    controller:
#    - 100.100.100.102
#    - 100.100.100.104
# <end>
#
#
#

class opnfv::resolver()
{
  if $::fuel_settings['role'] {
    if $::fuel_settings['role']  == 'primary-controller' {
      $role = 'controller'
    } else {
      $role = $::fuel_settings['role']
    }

    if ($::fuel_settings['opnfv']
        and $::fuel_settings['opnfv']['dns']
        and $::fuel_settings['opnfv']['dns'][$role]) {
      $nameservers=$::fuel_settings['opnfv']['dns'][$role]

      file { '/etc/resolv.conf':
            owner   => root,
            group   => root,
            mode    => '0644',
            content => template('opnfv/resolv.conf.erb'),
      }
# /etc/resolv.conf is re-generated at each boot by resolvconf, so we
# need to store there as well.
      file { '/etc/resolvconf/resolv.conf.d/head':
            owner   => root,
            group   => root,
            mode    => '0644',
            content => template('opnfv/resolv.conf.erb'),
      }
    }
  }
}

