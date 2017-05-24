# This is a copy of https://github.com/cloudbees/jenkins-ci.org-docker/ so that
# we can change the UID of the JENKINS user to something more amenable, otherwise
# we could just have done FROM jenkins:{version}

FROM java:openjdk-7-jdk
MAINTAINER Neilen Marais <nmarais@ska.ac.za>
ENV UPDATED_ON 2015-04-02

# Handle apt deps
COPY apt-requirements.txt /
# Leave /apt/lists so that tests can install packages as needed
RUN apt-get update && apt-get install -y $(cat apt-requirements.txt) # && rm -rf /var/lib/apt/lists/*


# Handle python deps
RUN curl -L https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && python /tmp/get-pip.py
COPY python-requirements.txt /
RUN pip install -r python-requirements.txt

# Install script to set up python build environment
COPY setup_virtualenv.sh /usr/local/bin/
RUN chmod a+rx /usr/local/bin/setup_virtualenv.sh

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_UID 2000
# Jenkins is ran with user `jenkins`, uid = JENKINS_UID
# If you bind mount a volume from host/volume from a data container,
# ensure you use same uid
RUN useradd -d "$JENKINS_HOME" -u "$JENKINS_UID" -m -s /bin/bash jenkins

## Allow jenkins user to use sudo to perform a limited subset of commands
# without a password such as installing new packages.
RUN adduser jenkins sudo

COPY jenkins-apt-sudoers /etc/sudoers.d/
RUN chmod 0440 /etc/sudoers.d/jenkins-apt-sudoers

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-angent-port.groovy

ENV JENKINS_VERSION 2.62
# could use ADD but this one does not check Last-Modified header
# see https://github.com/docker/docker/issues/8331
RUN curl -L http://mirrors.jenkins-ci.org/war/2.62/jenkins.war -o /usr/share/jenkins/jenkins.war
ENV JENKINS_UC https://updates.jenkins-ci.org
RUN chown -R jenkins "$JENKINS_HOME" /usr/share/jenkins/ref
# for main web interface:
EXPOSE 8080
# will be used by attached slave agents:
EXPOSE 50000

# # Experimental hack to allow jenkins user to sudo
# RUN echo 'jenkins:blah' | chpasswd

USER jenkins
COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]
# from a derived Dockerfile, can use `RUN plugin.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh

