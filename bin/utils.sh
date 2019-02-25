#!/bin/bash

function RequireDocker()
{
    if [ ! -x "$(command -v docker)" ]; then
        echo "Docker is not installed." 1>&2
        exit 1
   fi
}

function GetAbsPath()
{
    _SCRIPT_NAME=$1

    # Get the absolute path to the working directory
    pushd $(dirname $_SCRIPT_NAME) > /dev/null
    _SCRIPT_DIR=$(pwd -P)
    popd > /dev/null

    echo $_SCRIPT_DIR
}

PROVIDERS=(aws gcp az ibm local)
ARGUMENTS="please specify ONE of the following providers:[${PROVIDERS[*]}]"

if [ $# -ne 1 ]
then
    echo "arguments for $0: <CLOUD_PROVIDER>"
    echo $ARGUMENTS

    exit 1
fi

function contains()
{
    local element match="$1"
    shift
    for element
    do
        if [[ "$element" == "$match" ]]; then
            echo "SUCCESS"
            return 0
        fi
    done
    echo "ERROR"
    return 1
}


function IsWindows()
{
    if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
        echo true
    else
        echo false
    fi

    return 0
}
