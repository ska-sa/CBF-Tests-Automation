#!/usr/bin/env python

from __future__ import absolute_import
from __future__ import print_function

import __builtin__
import os
try:
    from fabric.api import task, sudo, run, cd, local, env, warn_only, get
    from fabric.context_managers import settings
except ImportError:
    from pip._internal import main as pip
    pip(['install', '--user', 'fabric==1.12.1'])
    from fabric.api import task, sudo, run, cd, local, env, warn_only, get
    from fabric.context_managers import settings

JENKINS_UID = 2000
JENKINS_USER = os.environ.get('JENKINS_USER', 'jenkins')
JENKINS_HOME = '/home/{JENKINS_USER}'.format(**locals())
CONFIG_GIT_REPO = 'git@github.com:ska-sa/CBF-Jenkins-home.git'


class bcolors:
    BoldGreen = '\033[92m\033[1m'
    EndCmd = '\033[0m'

def print(*args, **kwargs):
    __builtin__.print('{0}{2}{1}'.format(bcolors.BoldGreen, bcolors.EndCmd, *args, **kwargs))


@task
def setup_jenkins_user():
    print ("NOTE: You will need to enter your SUDO password and hostname")
    with settings(warn_only=True):
        sudo('useradd -d "{JENKINS_HOME}" -u {JENKINS_UID} -m -s /bin/bash {JENKINS_USER}'.format(
            **globals()))
        print ("Setup a password for user: {JENKINS_USER}".format(**globals()))
        sudo('passwd {JENKINS_USER}'.format(**globals()))
        sudo('chmod -R o-xrw {JENKINS_HOME}'.format(**globals()))
        print("Generating SSH Keys")
        sudo('ssh-keygen -t rsa -f {JENKINS_HOME}/.ssh/id_rsa -q -N ""'.format(**globals()),
            user="{JENKINS_USER}".format(**globals()))
        print("\n\nCopy your `public key` and add new SSH keys to your GitHub profile.")
        print("Paste your ssh public key to your `GitHub ssh keys` in order to access private repos...")
        print("Open link in your browser: https://github.com/settings/ssh/new\n")
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
