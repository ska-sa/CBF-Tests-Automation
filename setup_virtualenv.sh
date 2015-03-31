#!/bin/bash

# Include this file in the jenkins job script to setup the virtualenv.
# Note: Must be a bash shell.
# eg. . ./opt/kattrap/bin/setup_virtualenv.sh

set -e 				# Abort on any errors

PY_PKG_LIST="nose mock coverage nosexcover pep8 pylint"

function install_pip_requirements {
FILENAME=$1                  # Filename to read requirements from.
WARNING=$2                   # If this is a depricated filename give a warning.
if [ -f "$FILENAME" ]
then
        if $WARNING
        then
                echo "!!! The use of $FILENAME is depricated."
                echo "!!! Please put you PIP build requirements"
                echo "!!! into pip-build-requirements.txt"
        fi
    # pip install --trusted-host pypi.camlab.kat.ac.za --pre -r $FILENAME
    cat $FILENAME | grep -v -e "^$" -e "^#" | sort -u | while read line
    do
        python "$(which pip)" install --trusted-host pypi.camlab.kat.ac.za --pre $line
        echo -n "."
    done
fi                           # do nothing if file is not found.           
}

function install_apt_requirements {
FILENAME=$1                  # Filename to read requirements from.
WARNING=$2                   # If this is a depricated filename give a warning.
if [ -f "$FILENAME" ]
then
        if $WARNING
        then
                echo "!!! The use of $FILENAME is depricated."
                echo "!!! Please put you APT build requirements"
                echo "!!! into apt-build-requirements.txt"
        fi
    sudo apt-get install -yfm $(cat $FILENAME)
fi                           # do nothing if file is not found.           
}

# MAIN
DEST_PATH=$1
if [ -z "$DEST_PATH" ]
then
    if [ -n "${WORKSPACE}" ]
    then
            DEST_PATH=${WORKSPACE}
    fi
fi

if [ -z "$DEST_PATH" ]
then
        echo "Could not determine where the workspace is."
        exit 1
fi

echo "Working in: ${DEST_PATH}"

cd "${DEST_PATH}"
virtualenv venv
. ./venv/bin/activate

if [ -z "${VIRTUAL_ENV}" ]
then
        echo "Could not create virtual env. $VIRTUAL_ENV"
        exit 2
fi

install_apt_requirements apt-build-requirements.txt false
python "$(which pip)" install -U $PY_PKG_LIST
install_pip_requirements system-requirements.txt true
install_pip_requirements requirements.txt true
install_pip_requirements pip-build-requirements.txt false

# Install Self.
# If the given DEST_PATH contains a setup.py we will install it.
# Previously had the install of self in the pip-build-requirements.txt 
# as a line with a '.'. That worked but on occasion we got wierd errors.

SETUP="${DEST_PATH}/setup.py"
if [ -f "${SETUP}" ]
then
        cd "${DEST_PATH}"
        # Install with dependencies.
        python "$(which pip)" install --trusted-host pypi.camlab.kat.ac.za --pre -U .
fi
