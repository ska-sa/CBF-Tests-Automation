=======================
CBF Jenkins Test Docker 
=======================

Define a Dockerfile that can build a docker instance useful for running CBF
Jenkins tests.

It assumes that the jenkins config/home directory is mounted on the container
volume `/var/jenkins_home`, which should be owned by UID=2000. E.g., to start it
with $JENKINS_HOME stored in /home/jenkins on the host machine:

  ::
     sudo docker build -t ska-sa-cbf/jenkins .
     sudo docker run -P -d -v /home/jenkins:/var/jenkins_home ska-sa-cbf/jenkins

Fabric utilities
================

A fabfile.py for use with the python Fabric package is included. It has tasks to
set up a Jenkins user with the correct UID on a host, and a task to do the git
checkout. Edit the CONFIG_GIT_REPO variable to change the git repository to clone.
