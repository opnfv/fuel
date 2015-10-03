#Copyright 2015 Open Platform for NFV Project, Inc. and its contributors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


#The required package for tempest is missing in Khaleesi along with EPEL for CentOS.
#This is a workaround for now since we require EPEL with Foreman/Puppet
#Also is a good place to put anything additional that we wish to install on the tempest node.

class opnfv::tempest {

  if $::osfamily == 'RedHat' {
    package { 'subunit-filters':
      ensure    => present,
    }
  }
}
