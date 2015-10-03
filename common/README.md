<!---
Copyright 2015 Open Platform for NFV Project, Inc. and its contributors

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
-->
# Common
This directory contains those files which belong to the "OPNFV-Installation and Maintenance" phase of the installation process.

The OPNFV install process consists of two main phases:
* **BASE-INSTALLATION:** Installation of plain-vanilla VM-manager (for BGS, OpenStack will be used as VM-Manager)
 * (repeatable) install of a plain vanilla VM-manager (for BGS this is OpenStack) that deploys to bare metal and supports a HA-setup of the VM-manager
 * the installation is performed with an installer “i” that creates a system in state BASE(i).
 * Files which are specific to an installer process are found in the directory of the associated installer approach (e.g. "fuel", "foreman", "opensteak", etc.)
 * Once the installation of the plain vanilla environment is complete, the installer i is terminated. The system is left in state BASE(i) and handed over to the second phase.
* **OPNFV-INSTALLATION and MAINTENANCE:** Installation of OPNFV specific modules, maintenance of the overall OPNFV installation
 * the system state for this second phase is called OPNFV(x) - where x is determined by a particular OPNFV release item.
 * install deltas to state BASE(i) to reach the desired state OPNFV(x). Deltas would be defined as a set of scripts/manifests. Given that the state BASE(i) differs by installer used, the scripts could also be different. That said, it is a clear objective to make these scripts as generic and independent from the installer used as possible.
 * maintain the system in state OPNFV(x)
 * decouple device configuration from orchestration; allow for different tool chains to be used for device configuration and orchestration. I.e. rather than couple device config and orchestration with a single tool such as puppet in master-agent mode, enable a single tool to be focused on config (e.g. puppet in master-less mode) and another one for orchestration (e.g. Ansible/Salt driving upgrade of components, download of particular manifests to the nodes etc.

