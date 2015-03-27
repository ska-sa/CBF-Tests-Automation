# This is a copy of https://github.com/cloudbees/jenkins-ci.org-docker/ so that
# we can change the UID of the JENKINS user to something more amenable

FROM java:openjdk-7u65-jdk
RUN apt-get update && apt-get install -y wget git curl zip && rm -rf /var/lib/apt/lists/*
ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_UID 2000
# Jenkins is ran with user `jenkins`, uid = JENKINS_UID
# If you bind mount a volume from host/vloume from a data container,
# ensure you use same uid
RUN useradd -d "$JENKINS_HOME" -u "$JENKINS_UID" -m -s /bin/bash jenkins

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-angent-port.groovy
ENV JENKINS_VERSION 1.596
# could use ADD but this one does not check Last-Modified header
# see https://github.com/docker/docker/issues/8331
RUN curl -L http://mirrors.jenkins-ci.org/war/1.596/jenkins.war -o /usr/share/jenkins/jenkins.war
ENV JENKINS_UC https://updates.jenkins-ci.org
RUN chown -R jenkins "$JENKINS_HOME" /usr/share/jenkins/ref
# for main web interface:
EXPOSE 8080
# will be used by attached slave agents:
EXPOSE 50000

# Handle python deps
RUN curl -L https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && python /tmp/get-pip.py

USER jenkins
COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]
# from a derived Dockerfile, can use `RUN plugin.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh

MAINTAINER Neilen Marais <nmarais@ska.ac.za>


