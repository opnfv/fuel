##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# daniel.smith@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

class opnfv::odl_docker
{
    case $::fuel_settings['role'] {
      /controller/: {

        file { "/opt":
                ensure => "directory",
             }

        file { "/opt/opnfv":
                ensure => "directory",
                owner => "root",
                group => "root",
                mode => 777,
             }

        file { "/opt/opnfv/odl":
                ensure => "directory",
             }

        file { "/opt/opnfv/odl/odl_docker_image.tar":
                ensure => present,
                source => "/etc/puppet/modules/opnfv/odl_docker/odl_docker_image.tar",
                mode => 750,
             }

        file { "/opt/opnfv/odl/docker-latest":
                ensure => present,
                source => "/etc/puppet/modules/opnfv/odl_docker/docker-latest",
                mode => 750,
             }

        file { "/opt/opnfv/odl/start_odl_conatiner.sh":
                ensure => present,
                source => "/etc/puppet/modules/opnfv/scripts/start_odl_container.sh",
                mode => 750,
             }
  }
 }
}

