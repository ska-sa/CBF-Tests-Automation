# Usage
# export JENKINS_USER="jenkins"
# docker run --restart=on-failure:10 -d --name=${JENKINS_USER} -p 8080:8080 -p 50000:50000 -v /home/${JENKINS_USER}:/var/jenkins_home ska-sa-cbf/${JENKINS_USER}

FROM java:openjdk-8-jdk
LABEL maintainer="Mpho Mphego <mmphego@ska.ac.za>"
ARG DEBIAN_FRONTEND=noninteractive
# RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
COPY apt-requirements.txt /
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y --no-install-recommends "$(grep -vE "^\s*#" apt-requirements.txt | tr "\n" " ")" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Handle python deps
RUN curl https://bootstrap.pypa.io/get-pip.py | python && \
    pip install --no-cache-dir --disable-pip-version-check -U virtualenv

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_UID 2000
# Jenkins is ran with user `jenkins`, uid = JENKINS_UID
# If you bind mount a volume from host/volume from a data container,
# ensure you use same uid
RUN useradd -d "${JENKINS_HOME}" -u "${JENKINS_UID}" -m -s /bin/bash jenkins

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
# Copy in local config files
# COPY plugins.sh /usr/local/bin/plugins.sh
# COPY install-plugins.sh /usr/local/bin/install-plugins.sh
# RUN chmod +x /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy \
#    && chmod +x /usr/local/bin/plugins.sh \
#    && chmod +x /usr/local/bin/jenkins.sh \
#    && chmod +x /usr/local/bin/install-plugins.sh

# Jenkins Mirrors: http://mirrors.jenkins.io/status.html
# LTS version
ENV JENKINS_VERSION 2.107.1
RUN bash -c "ping -c 5 www.google.com"

# Backup links
# -----------------------------------------
# RUN bash -c "wget 'https://mirrors.tuna.tsinghua.edu.cn/jenkins/war/${JENKINS_VERSION}/jenkins.war' -O /usr/share/jenkins/jenkins.war"
# RUN bash -c "wget 'http://mirrors.jenkins-ci.org/war/${JENKINS_VERSION}/jenkins.war' -O /usr/share/jenkins/jenkins.war"
# -----------------------------------------
RUN wget "http://mirrors.jenkins.io/war-stable/${JENKINS_VERSION}/jenkins.war" -O /usr/share/jenkins/jenkins.war
#RUN axel "http://mirrors.jenkins-ci.org/war/${JENKINS_VERSION}/jenkins.war" -o /usr/share/jenkins/jenkins.war
ENV JENKINS_UC https://updates.jenkins-ci.org
RUN chown -R jenkins "${JENKINS_HOME}" /usr/share/jenkins/ref

# for main web interface:
EXPOSE 8080
# will be used by attached slave agents:
EXPOSE 50000

USER jenkins
COPY jenkins.sh /usr/local/bin/jenkins.sh
#RUN chmod +x /usr/local/bin/jenkins.sh
ENTRYPOINT ["/bin/bash", "/usr/local/bin/jenkins.sh"]

