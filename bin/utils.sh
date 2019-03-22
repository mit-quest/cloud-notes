#!/bin/bash

# Check if file is already sourced
[ -n "$__UTILS__" ] && return || readonly __UTILS__=1

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

# Get the absolute path to the provided script, including
# the script name.
# ARGUMENTS:
#   _FILE_NAME - The name of the file or script to find
#                  the absolute filesystem path for
# RETURNS:
#   The absolute path to the file as _FILE_PATH
function GetAbsPath()
{
    local _FILE_NAME=$1

    pushd $(dirname $_FILE_NAME) > /dev/null
    local _FILE_PATH="$(pwd -P)/$(basename $_FILE_NAME)"
    popd > /dev/null

    echo "$_FILE_PATH"
}

# Valid Platforms/Providers
readonly PROVIDERS=(aws gcp az ibm local)

# Checks for a value given the contents of an Array
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
        echo $_ERROR_MSG 1>&2
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

function ToLower()
{
    echo "$1" | awk '{print tolower($0)}'
}

function GetId()
{
    echo $1 | cksum | awk '{ print $1 }'
}

function BackgroundTask()
{
    nohup $($@) &>/dev/null &
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

# Gets pseudo-unique container name based on provider specification
# ARGUMENTS:
#   _PREFIX   - The base name for the container.
#   _PROVIDER - The platform provider.
#
# RETURNS:
#   _CONTAINER_NAME (string).
#
function GetContainerName()
{
    local _prefix=$1
    local _provider=$2

    CheckProvider $_provider

    _postfix=
    if [ -z "${_provider/local/}" ]; then
        _postfix="-$(hostname)"
    fi

    _container_name=$(ToLower "${_prefix}${_postfix}")
    echo $_container_name
}

# Given a directory name, enumerates the contents of the folder
# AGUMENTS:
#   _FOLDER     - The path to the folder
#   _BLACK_LIST - Configuration file to blacklist specific files
#                 from being enumerated
#
function EnumerateFolderContents()
{
    local _FOLDER=$1
    local _BLACK_LIST=$2

    find "$_FOLDER" -name "*" | sed 's|'$_FOLDER/'||' | grep -vf $_BLACKLIST
}

# Unset a readonly variable.
# ARGUMENTS:
#    _READONLY_VAR - The name of the readonly variable
#
function UnsetReadonly()
{
    # Requires gdb. This function should not cause a failure
    # if gdb is not installed. Return if gdb is not found.
    if [ ! -x "$(command -v gdb)" ]; then 
        return 0
    fi

# Don't move the following lines for formatting reasons.
# Formatted to work with the EOF block.
$_READONLY_VAR=$1

# Unset will fail. Redirect stderr to stdout and capture
# return value 
unset $_READONLY_VAR > /dev/null 2>&1
if [ $? -ne 0 ]; then
    gdb -n <<EOF > /dev/null 2>&1
 attach $$
 call unbind_variable("$_READONLY_VAR")
 detach
 quit
EOF
fi
}

function UnsetUtils()
{
    UnsetReadonly PROVIDERS
    UnsetReadonly __UTILS__

    unset -f RequireDocker
    unset -f GetAbsPath
    unset -f PermissionsCheck
    unset -f IsRoot
    unset -f DockerMember
    unset -f Contains
    unset -f CheckProvider
    unset -f InWSLBash
    unset -f GetContainerName
    unset -f ToLower
    unset -f UnsetReadonly
    unset -f UnsetUtils
}
