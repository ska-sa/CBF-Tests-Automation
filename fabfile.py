from fabric.api import task, sudo, run, cd, local, env, warn_only, get

JENKINS_UID = 2000
JENKINS_HOME = '/home/jenkins'
CONFIG_GIT_REPO = 'git@github.com:ska-sa/CBF-Tests-Automation.git'

@task
def setup_jenkins_user():
    sudo('useradd -d "{JENKINS_HOME}" -u {JENKINS_UID} '
         '-m -s /bin/false jenkins'.format(**globals()))
    sudo('chmod -R o-xrw {JENKINS_HOME}'.format(**globals()))

@task
def checkout_cbf_jenkins_config():
    with cd(JENKINS_HOME):
        sudo('git init .', user='jenkins')
        # This does not work with older versions of git.
        # sudo('git config --local push.default simple', user='jenkins')
        sudo('git config --local user.email "fake-jenkins-user@ska.ac.za.fake"',
             user='jenkins')
        sudo('git config --local user.name "CBF Jenkins automaton"',
             user='jenkins')
        sudo('git remote add origin "{CONFIG_GIT_REPO}"'.format(**globals()),
             user='jenkins')
        sudo('git fetch', user='jenkins')
        sudo('git checkout master -f ', user='jenkins')
