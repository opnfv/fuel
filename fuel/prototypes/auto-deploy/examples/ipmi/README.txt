This is a hybrid IPMI DHA, where the Fuel master is run as a KVM
VM, but all other nodes are real iron under IPMI control.

In "conf" is an example dea.yaml, dha.yaml and a VM definition for the
Fuel master. You need to tune these so they match your specific
environment. In addition you need to create a bridge from the VM to
the admin (PXE) network of the physical nodes. An example snippet for
/etc/network/interfaces which also configures NAT can be found in the
README.txt in conf.

