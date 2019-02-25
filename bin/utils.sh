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
    local _PROVIDER=$1
    local _ERROR_MSG="please specify a valid Provider. providers:[${PROVIDERS[*]}]"

    Contains $_PROVIDER ${PROVIDERS[@]}
    if [ $? -ne 0 ]
    then
        echo $_ERROR_MSG
        exit 1
    fi
}

# Checks the current environment to determine if the active bash shell
# is running on Windows Subsystem for Linux.
#
function InWSLBash()
{
    if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Determines if the current user is part of the docker group
# required as part of the post setup of a docker installation
#
function DockerMember()
{
    if groups $(id -urn) | grep &>/dev/null "\bdocker\b"; then
        return 0
    else
        return 1
    fi
}

# Checks if the user is attempting to run a sript as root.
#
function IsRoot()
{
    if [ $(id -u) = 0 ]; then
        return 0
    else
        return 1
    fi
}

# If effective user id is 0 (a root user), then print the provided
# error message to stderr.
#
function PermissionsCheck()
{
    _ROOT_WARNING="\
WARNING: Running as root. This may cause unintended side \
effects with deployments. If another user runs as root, they \
may override this deployment. To avoid this error, make sure you \
are a member of the docker group"

    _ERROR_MESSAGE="\
ERROR: Running as an under-privileged user. \
Make sure you are part of the docker group."

    IsRoot
    if [ $? = 0 ]; then
        echo "$_ROOT_WARNING" 1>&2
    else
        DockerMember
        if [ $? = 1 ]; then
            echo "$_ERROR_MESSAGE" 1>&2
            return 1
        fi
    fi

    return 0
}
