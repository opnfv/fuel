####################################################################
# Copyright (c) 2015 Ericsson AB and others.
# daniel.smith@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#
#  DOCKERFILE TO CREATE ODL IN CONTAINER AND EXPOSE DLUX AND OVSDB TO ODL
#
#############################################################################


#Set the base image - note: the current release of Karaf is using Jdk7 and alot of 12.04, so we will use it rather than 14.04 and backport a ton of stuff
FROM ubuntu:12.04

# Maintainer Info
MAINTAINER Daniel Smith


#Run apt-get update one start just to check for updates when building
RUN echo "Updating APT"
RUN apt-get update
RUN echo "Adding wget"
RUN apt-get install -y wget
RUN apt-get install -y net-tools
RUN apt-get install -y openjdk-7-jre
RUN apt-get install -y openjdk-7-jdk
RUN apt-get install -y openssh-server
RUN apt-get install -y vim
RUN apt-get install -y expect
RUN apt-get install -y daemontools
RUN mkdir -p /opt/odl_source
RUN bash -c 'echo "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64" >> ~/.bashrc'



#Now lets got and fetch the ODL distribution
RUN echo "Fetching ODL"
RUN wget https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.2.3-Helium-SR3/distribution-karaf-0.2.3-Helium-SR3.tar.gz -O /opt/odl_source/distribution-karaf-0.2.3-Helium-SR3.tar.gz

RUN echo "Untarring ODL inplace"
RUN mkdir -p /opt/odl
RUN tar zxvf /opt/odl_source/distribution-karaf-0.2.3-Helium-SR3.tar.gz -C /opt/odl

RUN echo "Installing DLUX and other features into ODL"
#COPY dockerfile/container_scripts/start_odl_docker.sh /etc/init.d/start_odl_docker.sh
COPY container_scripts/start_odl_docker_container.sh /etc/init.d/
COPY container_scripts/speak.sh /etc/init.d/
#COPY dockerfile/container_scripts/speak.sh /etc/init.d/speak.sh
RUN chmod 777 /etc/init.d/start_odl_docker_container.sh
RUN chmod 777 /etc/init.d/speak.sh



# Expose the ports

# PORTS FOR BASE SYSTEM AND DLUX
EXPOSE 8101
EXPOSE 6633
EXPOSE 1099
EXPOSE 43506
EXPOSE 8181
EXPOSE 8185
EXPOSE 9000
EXPOSE 39378
EXPOSE 33714
EXPOSE 44444
EXPOSE 6653

# PORTS FOR OVSDB AND ODL CONTROL
EXPOSE 12001
EXPOSE 6640
EXPOSE 8080
EXPOSE 7800
EXPOSE 55130
EXPOSE 52150
EXPOSE 36826

# set the ENTRYPOINT - An entry point allows us to run this container as an exectuable
CMD ["/etc/init.d/start_odl_docker_container.sh"]
