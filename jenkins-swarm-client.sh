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
SWARM_HOME="${USER_HOME}/jenkinsswarm/"
JAR="${SWARM_HOME}swarm-client-jar-with-dependencies.jar"
LOG="${SWARM_HOME}/jenkinsswarm/jenkins-swarm-client.log"
MASTER="http://localhost:8080"
USERNAME="user"
PASSWORD="bitnami"

# Swarm client option
DESCRIPTION="dbelab04"
EXECUTORS=1
FSROOT="${SWARM_HOME}/fsroot"
LABELS="cmc"

OPTS="-description \"${DESCRIPTION}\" \
      -executors ${EXECUTORS} \
      -fsroot ${FSROOT} \
      -labels \"${LABELS}\" \
      -username ${USERNAME} \
      -password ${PASSWORD}"

PIDFILE="/var/run/jenkins-swarm-client.pid"
ARGS="-server -Djava.awt.headless=true -jar $JAR $OPTS"
JAVA_HOME="/etc/alternatives/java"
DAEMON="/usr/bin/java"

test -x $DAEMON || exit 1

case $1 in
   start)
       log_daemon_msg "Starting jenkins-swarm-client"
       start-stop-daemon --start --quiet --chuid $USER --background --make-pidfile --pidfile $PIDFILE --startas $DAEMON -- $ARGS
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
