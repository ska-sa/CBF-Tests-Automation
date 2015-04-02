=======================
CBF Jenkins Test Docker 
=======================

Define a Dockerfile that can build a docker instance useful for running CBF
Jenkins tests.

It assumes that the jenkins config/home directory is mounted on the container
volume `/var/jenkins_home`, which should be owned by UID=2000. E.g., to start it
with $JENKINS_HOME stored in /home/jenkins on the host machine, exposed on a
random TCP port:

  ::
     sudo docker build -t ska-sa-cbf/jenkins .
     sudo docker run -P -d -v /home/jenkins:/var/jenkins_home ska-sa-cbf/jenkins

Howtos
======

Starting from scratch, the subsection steps need to be performed in order. The
`host` referred to below is the server/VM that will be hosting the Jenkins
docker instance.

Set up the host
---------------

1. Install docker using `whatsoever steps are necessary
   <https://docs.docker.com/installation/>`_. Quite simple if your host has a
   packaged docker, but for Debian wheezy one needs :ref:`extra steps
   <wheezy_host_setup>`

2. Fix DNS config if you use a localhost dnsmasq (like Ubuntu's using
   NetworkManager, or correlator controller servers) by adding to the
   `/etc/default/docker` file ::

    DOCKER_OPTS="--dns 196.24.41.8 --dns 196.24.41.9"

Set up a Jenkins user and data volume
-------------------------------------

This Jenkins image exports a data volume `/var/jenkins_home` that is required to
store the Jenkins configuration. This volume should be owned by a `jenkins` user
with UID 2000 (as configured in `Dockerfile`). It is recommended that the volume
(if stored on the host) should not be world readable since the jenkins
configuration might contain sensitive information and it seems Jenkins itself is
not too smart about using appropriate permissions.  

If using the default CBF config, the `setup_jenkins_user` and
`checkout_cbf_jenkins_config` :ref:`fabric commands <fabric_utilities>` included
in this repository. They should also set up permissions appropriately. 

.. _deploy_jenkins_container:

Deploy the Jenkins container on the host
----------------------------------------

This section is only a suggestion, there are many ways to manage docker images,
containers and volumes, but this is a simple one :)

1. Check the current repository out somewhere on the host, change to the
   repository directory and run ::

    sudo docker build -t ska-sa-cbf/jenkins .

2. Start the jenkins service by running ::

    sudo docker run --name=jenkins --restart=on-failure:10 -d -p 8080:8080\
        -v /home/jenkins:/var/jenkins_home ska-sa-cbf/jenkins
	
   This will create a container using the docker image we just built named
   `jenkins` as a daemon.  It should be visible in the list if the `sudo docker
   ps` command is run

   This container will start automatically at boot-time,
   and it will automatically be restarted up to 10 times if it exits with an
   error condition. Modify the `--restart` parameter to change this behaviour.

   The Jenkins web interface will be exposed on port 8080 of all the
   host network interfaces. Modify the `-p` parameter to `-p ${host_port}:8080`
   to use a different port, or consult the docker documentation for limiting it
   to specific interfaces.

   The container data volume `/var/jenkins_home` will be linked to the
   `/home/jenkins` directory on the host. This directory should be owned by the
   `jenkins` user. It is recommended that it not be world readable since the
   jenkins configuration might contain sensitive information and it seems
   Jenkins itself is not too smart about using appropriate permissions.


.. _wheezy_host_setup:

Upgrade / rebuild the Jenkins container
---------------------------------------

The Jenkins version is pegged in the Docker file using the `JENKINS_VERSION` env
variable. To upgrade the Jenkins version, edit `JENKINS_VERSION` in `Dockerfile`
to the desired version. To force an update of the container to get e.g. security updates, modify the
`UPDATED_ON` environment variable. Then follow the :ref:`deploy_jenkins_container`
instructions, but before doing the `docker run` command, stop and delete the
current Jenkins container ::

  sudo docker stop jenkins
  sudo docker rm jenkins # Deletes the current jenkins container


Installing docker on Debian Wheezy
----------------------------------

Extra steps only needed when installing on Debian Wheezy; newer versions have
per-packaged docker.io love. 

Add the wheezy backports repository so that a new-enough kernel can be installed
for docker by placing into `/etc/apt/sources.list.d/wheezy-backports.list` ::

    deb http://http.debian.net/debian wheezy-backports main

Perform the following steps in a shell (substitute sudo with whatever rootness
method you use) ::

    sudo apt-get update
    sudo apt-get install -t wheezy-backports linux-image-amd64
    # Apparmor info: https://wiki.debian.org/AppArmor/HowToUse
    sudo apt-get install apparmor apparmor-profiles apparmor-utils
    sudo perl -pi -e \
      's,GRUB_CMDLINE_LINUX="(.*)"$,GRUB_CMDLINE_LINUX="$1 apparmor=1 security=apparmor",' /etc/default/grub
    sudo update-grub
    sudo shutdown -rf now
    apt-get install apt-transport-https
    # From https://get.docker.com/ script
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
      --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
    sudo sh -c "echo deb https://get.docker.com/ubuntu docker main \ 
      > /etc/apt/sources.list.d/docker.list"
    sudo apt-get update && sudo apt-get install lxc-docker

.. _fabric_utilities:

Fabric utilities
================

A fabfile.py for use with the python Fabric package is included. It has tasks to
set up a Jenkins user with the correct UID on a host, and a task to do the git
checkout. Edit the CONFIG_GIT_REPO variable to change the git repository to
clone. Your host needs to have sudo installed, and the user used to connect to
host must have sudo rights. Also the Python `fabric` package must be installed.

Example for setting up a Jenkins user and checking out our Jenkins configuration
on a host `dbe-host0` in the home directory of the `jenkins` user, run in shell
in the current repository directory ::

  fab -H user@dbe-host0 setup_jenkins_user
  fab -H user@dbe-host0 checkout_cbf_jenkins_config

 
