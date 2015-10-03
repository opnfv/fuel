#!/bin/bash
# a "cheat" way to install docker on the controller
# can only be used if you have a connecting out to the internet

# Usage: ./install_docker.sh <ip of default route to remove> <ip of default gw to add>

OLDGW=$1
#!/bin/bash
# a "cheat" way to install docker on the controller
# can only be used if you have a connecting out to the internet

# Usage: ./install_docker.sh <ip of default route to remove> <ip of default gw to add>

OLDGW=$1
NEWGW=$2
IMAGEPATH=/opt/opnfv
IMAGENAME=odl_docker_image.tar
SOURCES=/etc/apt/sources.list


if [ "$#" -ne 2]; then
        echo "Two args not provided, will not touch networking"
else

        # Fix routes
        echo "Fixing routes"
        #DEBUG
        netstat -rn

        echo "delete old def route"
        route delete default gw $1
        echo "adding new def route"
        route add default gw $2

        echo " you should see a good nslookup now"
        nslookup www.google.ca
#!/bin/bash
# a "cheat" way to install docker on the controller
# can only be used if you have a connecting out to the internet

# Usage: ./install_docker.sh <ip of default route to remove> <ip of default gw to add>

OLDGW=$1
NEWGW=$2
IMAGEPATH=/opt/opnfv
IMAGENAME=odl_docker_image.tar
SOURCES=/etc/apt/sources.list


if [ "$#" -ne 2]; then
        echo "Two args not provided, will not touch networking"
else

        # Fix routes
        echo "Fixing routes"
        #DEBUG
        netstat -rn

        echo "delete old def route"
        route delete default gw $1
        echo "adding new def route"
        route add default gw $2

        echo " you should see a good nslookup now"
        nslookup www.google.ca
fi


if egrep "mirrors.txt" $SOURCES
then
        echo "Sources was already updated, not touching"
else
        echo "adding the closests mirrors and docker mirror to the mix"
        echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise main restricted universe multiverse" >> /etc/apt/sources.list
        echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-updates main restricted universe multiverse" >> /etc/apt/sources.list
        echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-backports main restricted universe multiverse" >> /etc/apt/sources.list
        echo "deb mirror://mirrors.ubuntu.com/mirrors.txt precise-security main restricted universe multiverse" >> /etc/apt/sources.list
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
        echo "deb https://get.docker.com/ubuntu docker main " > /etc/apt/sources.list.d/docker.list
fi

echo "Updating"
apt-get update
echo "Installing Docker"
apt-get install -y lxc-docker

echo "Loading ODL Docker Image"
docker load -i $IMAGEPATH/$IMAGENAME


