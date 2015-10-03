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
#
#Class installs opendaylight with a default rest port of 8081
#This is to work around OpenStack Swift which also uses common port 8080

class opnfv::odl_service {
     if !$odl_rest_port { $odl_rest_port = '8081'}
     class {"opendaylight":
       extra_features => ['odl-base-all', 'odl-aaa-authn', 'odl-restconf', 'odl-nsf-all', 'odl-adsal-northbound', 'odl-mdsal-apidocs', 'odl-ovsdb-openstack', 'odl-ovsdb-northbound', 'odl-dlux-core'],
       odl_rest_port  => $odl_rest_port,
     }
}
