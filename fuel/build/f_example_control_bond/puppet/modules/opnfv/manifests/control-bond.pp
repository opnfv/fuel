##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Class: opnfv::control-bond
#
# Bridge control and management networks together using OVS.
#
#

class opnfv::control-bond {
  notify { '*** In Opnfv::control-bond-start ***': }

  file { "/etc/init.d/control-bond":
         source => "puppet:///modules/opnfv/control-bond",
         owner  => 'root',
         group  => 'root',
         mode   => '0755',
         notify => Service["control-bond"]
       }


  service { "control-bond":
        ensure => running,
        require => [ File["/etc/init.d/control-bond"], Service["openvswitch-service"] ],
  }

  # Only start scripts - we don't want to bring down
  # bridge during shutdown

  file { "/etc/rc2.d/S18control-bond":
         ensure => 'link',
         target => '/etc/init.d/control-bond',
  }

  file { "/etc/rc3.d/S18control-bond":
         ensure => 'link',
         target => '/etc/init.d/control-bond',
  }

  file { "/etc/rc4.d/S18control-bond":
         ensure => 'link',
         target => '/etc/init.d/control-bond',
  }

  file { "/etc/rc5.d/S18control-bond":
         ensure => 'link',
         target => '/etc/init.d/control-bond',
  }
}
