#!/usr/bin/env bash
# Script that checks Java version if its JAVA8 else it will install it.
# Author: Mpho Mphego <mmphego@ska.ac.za>


printf "Checking Java version\n"
# Allows us to read user input below, assigns stdin to keyboard
exec < /dev/tty
JAVA_VER=$(java -version 2>&1 | grep -i version)
if [ $(echo ${JAVA_VER} | grep 1.8 > /dev/null; printf $?) -ne 0 ]; then
    printf "Java Version is out-of-date: ${JAVA_VER}\n"
    printf "Do you wish update your JAVA runtime?\n"
    printf "NOTE: This installer assumes you are running Debian 7 Wheezy\n";
    printf "Enter Yes -> 1 or No -> 2\n"
    select yn in "Yes" "No"; do
    case $yn in
            Yes ) sudo sh -c 'echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" >> /etc/apt/sources.list';
                 sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886;
                 sudo apt-get update -qq;
                 sudo apt-get install -y oracle-java8-installer;
                 break;;
            No ) printf "Oh well then! I guess you have a better idea!!!";
                 exit 1;;
        esac
    done
else
    printf "Java Version is supported: ${JAVA_VER}\n\n\n"
    exit 0;
fi;

