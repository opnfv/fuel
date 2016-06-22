#!/bin/bash

sudo apt-get install -y git git-review make curl p7zip-full

#install docker by https://docs.docker.com/engine/installation/linux/ubuntulinux/
#sudo apt-get install linux-image-extra-$(uname -r)
sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

cat << EOF | sudo tee /etc/apt/sources.list.d/docker.list
deb https://apt.dockerproject.org/repo ubuntu-trusty main
EOF
sudo apt-get update
sudo apt-get purge lxc-docker -y

#workaroud for large disk
sudo mkdir /var/lib/docker
yes | sudo mkfs.ext4 /dev/sdb
sudo mount /dev/sdb /var/lib/docker

sudo apt-cache policy docker-engine
sudo apt-get install -y docker-engine
sudo service docker start
sudo groupadd docker
sudo usermod -aG docker vagrant
cp -r /fuel /home/vagrant
