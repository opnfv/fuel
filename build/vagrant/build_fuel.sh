#!/bin/bash

sudo apt-get update
sudo apt-get install -y vagrant virtualbox
vagrant destroy -f; vagrant up
vagrant ssh -c "sudo apt-get update; sudo apt-get install -y linux-generic-lts-vivid"
vagrant reload
vagrant ssh -c "/vagrant/setup_fuel.sh"
vagrant ssh -c "cd fuel/build; make; cp fuel*.iso /vagrant"
