#!/bin/sh

### BEGIN INIT INFO
# Provides:          jenkinsvmfarm
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Should-Start:      $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: jenkins swarm build slave
# Description:       jenkins swarm build slave assigned to a Jenkins master
### END INIT INFO
set -e

. /lib/lsb/init-functions

USER=cbf-test
USER_HOME="/home/${USER}"
SWARM_HOME="${USER_HOME}/jenkinsswarm"
JAR="${SWARM_HOME}/swarm-client-jar-with-dependencies.jar"
LOG="${SWARM_HOME}/jenkins-swarm-client.log"
PASSWORD_FILE="${SWARM_HOME}/jenkins_password"
MASTER="http://localhost:8080"
USERNAME="user"
#PASSWORD="bitnami"

# Swarm client option
DESCRIPTION="dbelab04 CMC"
EXECUTORS=1
FSROOT="${SWARM_HOME}/fsroot"
LABELS="cmc"
NAME="dbelab04"

OPTS="-description \"${DESCRIPTION}\" \
      -name ${NAME} \
      -master ${MASTER} \
      -executors ${EXECUTORS} \
      -fsroot ${FSROOT} \
      -labels \"${LABELS}\" \
      -username ${USERNAME} \
      -password '@'${PASSWORD_FILE}"
    # -password ${PASSWORD}

# Note, the --password @PASSWORD_FILE option to read the password from a file
# was added in v 2.0 of the swarm plugin
#
# See https://issues.jenkins-ci.org/browse/JENKINS-26620
#
# Seems the option is undocumented, so it may break in the future?

PIDFILE="/var/run/jenkins-swarm-client.pid"
ARGS="-server -Djava.awt.headless=true -jar $JAR $OPTS"
JAVA_HOME="/etc/alternatives/java"
DAEMON="/usr/bin/java"

test -x $DAEMON || exit 1

case $1 in
   start)
       log_daemon_msg "Starting jenkins-swarm-client"
       start-stop-daemon --start --chuid $USER --background --make-pidfile --pidfile $PIDFILE --startas /bin/bash -- -c "exec $DAEMON $ARGS >  $LOG 2>&1"
 
       log_end_msg $?
       ;;
   stop)
       if [ -e $PIDFILE ]; then
          log_daemon_msg "Stopping jenkins-swarm-client"
          start-stop-daemon --stop --quiet --pidfile $PIDFILE
          log_end_msg $?
          rm -f $PIDFILE
       fi
       ;;
   restart)
        $0 stop
        sleep 2
        $0 start
        ;;
   status)
        status_of_proc -p $PIDFILE "$DAEMON" jenkins-swarm-client
  RETVAL=$?
	;;

   *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1

esac

exit 0
