#!/bin/sh
### BEGIN INIT INFO
# Provides:          graylog2-server
# Required-Start:    $network $local_fs $syslog $remote_fs
# Required-Stop:     $network $local_fs $syslog $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts Graylog2 server
# Description:       Graylog2 is an open source syslog implementation that
#                    stores your logs in ElasticSearch. It consists of a
#                    server written in Java that accepts your syslog messages
#                    via TCP or UDP and stores it in the database. The second
#                    part is a Ruby on Rails web interface that allows you to
#                    view the log messages.
### END INIT INFO

# Author: Claudio Filho <claudio.filho@locaweb.com.br>

PATH=/bin:/usr/bin:/sbin:/usr/sbin
NAME=graylog2-server
DESC=graylog2-server
DEFAULT=/etc/default/$NAME

if [ `id -u` -ne 0 ]; then
   echo "You need root privileges to run this script"
   exit 1
fi

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

# The first existing directory is used for JAVA_HOME (if JAVA_HOME is not defined in $DEFAULT)
JDK_DIRS="/usr/lib/jvm/java-7-oracle /usr/lib/jvm/java-6-sun /usr/lib/jvm/java-7-openjdk /usr/lib/jvm/java-6-openjdk /usr/lib/jvm/java-7-openjdk-amd64/ /usr/lib/jvm/java-6-openjdk-amd64/"

# Look for the right JVM to use
for jdir in $JDK_DIRS; do
    if [ -r "$jdir/bin/java" -a -z "${JAVA_HOME}" ]; then
        JAVA_HOME="$jdir"
    fi
done
export JAVA_HOME

# The following variables can be overwritten in $DEFAULT

DIR=/usr/share/java
JAVA_OPTS="-Xms2g -Xmx2g -Xss256k -XX:MaxPermSize=1g"
PIDFILE=/var/run/$NAME.pid

# End of variables that can be overwritten in $DEFAULT

# overwrite settings from default file
if [ -f "$DEFAULT" ]; then
    . "$DEFAULT"
fi

set -e

case "$1" in
  start)
    if [ -z "$JAVA_HOME" ]; then
        log_failure_msg "no JDK found - please set JAVA_HOME"
        exit 1
    fi

    log_daemon_msg "Starting $DESC: "

    if [ -f "$PIDFILE" ] && [ $(ps -o pid --no-headers -p `cat $PIDFILE`) ]; then
        log_success_msg "$DESC is running with pid `cat $PIDFILE`"
        exit 1
    fi

    if start-stop-daemon -S -q -b -o --exec $JAVA_HOME/bin/java -- $JAVA_OPTS -jar $DIR/${NAME}.jar -p $PIDFILE; then
        log_end_msg 0
    else
        log_end_msg 1
    fi
    ;;
  stop)
    log_daemon_msg "Stopping $DESC"

    if [ -f "$PIDFILE" ]; then
        if [ $(ps -o pid --no-headers -p `cat $PIDFILE`) ]; then
            start-stop-daemon -K -q -o --pidfile $PIDFILE --retry=TERM/20/KILL/5 >/dev/null
	    if [ $? -eq 0 ]; then
                rm -f "$PIDFILE"
                log_end_msg 0
            elif [ $? -eq 3 ]; then
                PID=`cat $PIDFILE`
                log_failure_msg "Failed to stop $DESC (pid $PID)"
                exit 1
	    fi
        else
            log_progress_msg "$DESC is not running but pid file exists, cleaning up"
            rm -f "$PIDFILE"
            log_end_msg 0
        fi
    else
        log_success_msg "$DESC is not running."
    fi
    ;;
  status)
    if [ -f "$PIDFILE" ] && [ $(ps -o pid --no-headers -p `cat $PIDFILE`) ]; then
        log_success_msg "$DESC is running with pid `cat $PIDFILE`"
        exit 0
    elif [ -f "$PIDFILE" ]; then
        log_success_msg "$DESC is not running, but pid file exists."
        exit 1
    else
        log_success_msg "$DESC is not running."
        exit 3
    fi
    ;;
  restart|force-reload)
    if [ -f "$PIDFILE" ]; then
        $0 stop
        sleep 1
    fi
    $0 start
    ;;
  *)
    log_success_msg "Usage: $0 {start|stop|restart|force-reload|status}"
    exit 1
    ;;
esac

exit 0
