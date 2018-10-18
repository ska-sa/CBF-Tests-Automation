#!/usr/bin/env python

from __future__ import absolute_import
from __future__ import print_function

import __builtin__
import os
import time
import signal
from requests import get as geturl
try:
    from fabric.api import task, sudo, run, cd, local, env, warn_only, get
    from fabric.context_managers import settings
except ImportError:
    from pip._internal import main as pip
    pip(['install', '--user', 'fabric==1.12.1'])
    from fabric.api import task, sudo, run, cd, local, env, warn_only, get
    from fabric.context_managers import settings

UPSTART_DIR = '/etc/init.d'
CBFTEST_USER = "cbf-test"
CBFTEST_HOME = "/home/{CBFTEST_USER}".format(**locals())

JENKINS_UID = 2000
JENKINS_USER = os.environ.get('JENKINS_USER', 'jenkins')
JENKINS_HOME = '/home/{JENKINS_USER}'.format(**locals())

JENKINS_SWARM = "jenkins-swarm-client.sh"
JENKINS_SWARM_VERSION = 2.0
JENKINS_SWARM_CLIENT = (
    'https://raw.githubusercontent.com/ska-sa/CBF-Tests-Automation/master/'
    '{JENKINS_SWARM}'.format(**locals()))

CONFIG_GIT_REPO = 'git@github.com:ska-sa/CBF-Jenkins-home.git'

JENKINS_LOCALPORT = 8080
PORTFORWARDING_URL = 'serveo.net'
PORTFORWARDING_LOG = '.jenkins_http.log'

class bcolors:
    BoldGreen = '\033[92m\033[1m'
    EndCmd = '\033[0m'

def print(*args, **kwargs):
    __builtin__.print('{0}{2}{1}'.format(bcolors.BoldGreen, bcolors.EndCmd, *args, **kwargs))

@task
def setup_cbftest_user():
    print ("NOTE: You will need to enter your SUDO password and hostname")
    with settings(warn_only=True):
        print ("Creating new user: {CBFTEST_USER}".format(**globals()))
        sudo('useradd -d "{CBFTEST_HOME}" -m -s /bin/bash {CBFTEST_USER}'.format(**globals()))
        print ('Adding user to staff and docker groups.')
        sudo('groupadd docker')
        sudo('usermod -aG staff {CBFTEST_USER}'.format(**globals()))
        sudo('usermod -aG docker {CBFTEST_USER}'.format(**globals()))
        sudo('chgrp docker /usr/bin/docker')
        sudo('chgrp docker /var/run/docker.sock/')
        sudo('chmod a=rwX,o+t /tmp -R')
        print ("Setup a simple password for user: {CBFTEST_USER}".format(**globals()))
        sudo('passwd {CBFTEST_USER}'.format(**globals()))
        print("Generating SSH Keys")
        sudo('ssh-keygen -t rsa -f {CBFTEST_HOME}/.ssh/id_rsa -q -N ""'.format(**globals()),
            user="{CBFTEST_USER}".format(**globals()))
        sudo('mkdir -p {CBFTEST_HOME}/jenkinsswarm/fsroot'.format(**globals()),
            user="{CBFTEST_USER}".format(**globals()))
        print ("Downloading JAVA Jenkins swarm client v{JENKINS_SWARM_VERSION}".format(**globals()))
        sudo(
            "curl --create-dirs -sSLo {CBFTEST_HOME}/jenkinsswarm/swarm-client-jar-with-dependencies.jar"
            " https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/"
            "{JENKINS_SWARM_VERSION}/swarm-client-{JENKINS_SWARM_VERSION}-jar-with-"
            "dependencies.jar".format(**globals()), user="{CBFTEST_USER}".format(**globals()))

        if geturl(JENKINS_SWARM_CLIENT).status_code == 200:
            print ("Downloading Jenkins Swarm Client shell from github.com")
            sudo('wget {JENKINS_SWARM_CLIENT} -O {UPSTART_DIR}/{JENKINS_SWARM}'.format(**globals()))
            sudo('chmod a+x {UPSTART_DIR}/{JENKINS_SWARM}'.format(**globals()))
            print ("Starting Jenkins Swarm client automagically....")
            sudo('{UPSTART_DIR}/{JENKINS_SWARM} start'.format(**globals()))
            sudo("echo '{JENKINS_USER}:2345:respawn:/bin/bash {UPSTART_DIR}/{JENKINS_SWARM}' >> /etc/inittab".format(**globals()))

@task
def setup_jenkins_user():
    print ("NOTE: You will need to enter your SUDO password and hostname")
    with settings(warn_only=True):
        sudo('useradd -d "{JENKINS_HOME}" -u {JENKINS_UID} -m -s /bin/bash {JENKINS_USER}'.format(
            **globals()))
        sudo('usermod -aG docker {JENKINS_USER}'.format(**globals()))
        print ("Setup a password for user: {JENKINS_USER}".format(**globals()))
        sudo('passwd {JENKINS_USER}'.format(**globals()))
        sudo('chmod -R o-xrw {JENKINS_HOME}'.format(**globals()))
        print("Generating SSH Keys")
        sudo('ssh-keygen -t rsa -f {JENKINS_HOME}/.ssh/id_rsa -q -N ""'.format(**globals()),
            user="{JENKINS_USER}".format(**globals()))
        print("\n\nCopy your `public key` and add new SSH keys to your GitHub profile.")
        print("Paste your ssh public key to your `GitHub ssh keys` in order to access private repos...")
        print("Open link in your browser: https://github.com/settings/ssh/new\n")
        while True:
            if raw_input("Press any Keys & Enter to continue..."):
                break
        sudo('cat {JENKINS_HOME}/.ssh/id_rsa.pub'.format(**globals()))

@task
def checkout_cbf_jenkins_config():
    print ("This section assumes that {} has SUDO rights and, ".format(os.environ['USER']))
    print ("That you successfully added jenkins ssh public keys to your Github account.")
    with settings(warn_only=True):
        with cd(JENKINS_HOME):
            sudo('git init .', user="{JENKINS_USER}".format(**globals()))
            sudo('git config --local user.email "fake-jenkins-user@ska.ac.za.fake"',
                user="{JENKINS_USER}".format(**globals()))
            sudo('git config --local user.name "CBF Jenkins automaton"',
                user="{JENKINS_USER}".format(**globals()))
            sudo('git remote add origin {CONFIG_GIT_REPO}'.format(**globals()),
                    user="{JENKINS_USER}".format(**globals()))
            print("This will take a while, go make yourself a cup of coffee!!!")
            sudo('git fetch', user="{JENKINS_USER}".format(**globals()))
            sudo('git checkout master -f ', user="{JENKINS_USER}".format(**globals()))
            sudo('git pull -f ', user="{JENKINS_USER}".format(**globals()))
            sudo('git config --global push.default simple ', user="{JENKINS_USER}".format(**globals()))

@task
def expose_jenkins_http():
    print ('Exposing localhost port to the interweb')
    local(
        'ssh -R 8080:localhost:{JENKINS_LOCALPORT} {PORTFORWARDING_URL} '
        '> {PORTFORWARDING_LOG} 2>&1 &'.format(**globals()))
    time.sleep(5)
    with open(PORTFORWARDING_LOG) as f:
        url_link = [i.rstrip().split(' ')[-1] for i in f.readlines() if 'https://' in i]
    print ("Current URL: {url_link}".format(**locals()))

@task
def kill_jenkins_http():
    print ('Kill http exposing process')
    run(
        "pgrep -f 'ssh -R 8080:localhost:{JENKINS_LOCALPORT} {PORTFORWARDING_URL}' | "
        "xargs kill -9".format(**globals()))
