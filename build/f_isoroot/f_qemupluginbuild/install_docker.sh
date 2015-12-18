#!/bin/bash
# From prepare-build-env.sh of Fuel
# Check if docker is installed
if hash docker 2>/dev/null; then
  echo "Docker binary found, checking if service is running..."
  ps cax | grep docker > /dev/null
  if [ $? -eq 0 ]; then
    echo "Docker is running."
  else
    echo "Process is not running, starting it..."
    sudo service docker start
  fi
else
  # Install docker repository
  # Check that HTTPS transport is available to APT
  if [ ! -e /usr/lib/apt/methods/https ]; then
    sudo apt-get update
    sudo apt-get -y install -y apt-transport-https
  fi
  # Add the repository to APT sources
  echo deb http://mirror.yandex.ru/mirrors/docker/ docker main | sudo tee /etc/apt/sources.list.d/docker.list
  # Import the repository key
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
  # Install docker
  sudo apt-get update
  sudo apt-get -y install lxc-docker-1.7.1
fi
