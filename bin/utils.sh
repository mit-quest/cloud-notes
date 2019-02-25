#!/bin/bash

# Checks for Docker installation and causes script to exit
# if installation cannot be found.
#
function RequireDocker()
{
    if [ ! -x "$(command -v docker)" ]; then
        echo "Docker is not installed." 1>&2
        exit 1
   fi
}

# Get the absolute path to the provided script
# ARGUMENTS:
#   _FILE_NAME - The name of the file or script to find
#                  the absolute filesystem path for
# RETURNS:
#   The absolute path to the file as _FILE_PATH
function GetAbsPath()
{
    _FILE_NAME=$1

    pushd $(dirname $_FILE_NAME) > /dev/null
    _FILE_PATH=$(pwd -P)
    popd > /dev/null

    echo $_FILE_PATH
}

# Valid Platforms/Providers
PROVIDERS=(aws gcp az ibm local)

# Checks for a value givrn the contents of an Array
#
# ARGUMENTS:
#   _VALUE    - The value to look for in an array
#   _ELEMENTS - The array to look through for _VALUE
# RETURNS:

function Contains()
{
    # _ELEMENT the current item from _ELEMENTS
    # _VALUE the item to find in _ELEMENTS
    local _ELEMENT _VALUE="$1"
    shift

    for _ELEMENT
    do
        if [[ "$_VALUE" == "$_ELEMENT" ]]; then
            # 0 == true
            return 0
        fi
    done

    # 1 == false
    return 1
}

# Checks the supplied provider against a list of supported providers
# ARGUMENTS:
#   PROVIDER - The Cloud platform provider name.
#
function CheckProvider()
{
    local _PROVIDER = $1
    local ERROR_MSG="please specify ONE of the following providers:[${PROVIDERS[*]}]"

    if [ $# -ne 1 ]
    then
        echo "arguments for $0: <CLOUD_PROVIDER>"
        echo $ARGUMENTS

        exit 1
    fi
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
