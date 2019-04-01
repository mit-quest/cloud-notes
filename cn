#!/bin/bash

# Import our utility functions
. $(dirname ${BASH_SOURCE[0]})/bin/utils.sh
. $(dirname ${BASH_SOURCE[0]})/bin/build

trap UnsetUtils EXIT

RequireDocker
PermissionsCheck

if ! [ $# = 3 ]; then
    echo "USE: ${BASH_SOURCE[0]} <WORKSPACE> <DATA> <PROVIDER>" 1>&2
    exit 1
fi

# The repository or directory location of the AI workflow
__qi_workspace=$(GetAbsPath "$1")
CheckWorkspace "$__qi_workspace"

# The data location of the associated workflow
__qi_datasource=$(GetAbsPath "$2")
CheckDataSource "$__qi_datasource" "$__qi_workspace"

# The cloud platform provider
__qi_provider=$3
CheckProvider "$__qi_provider"

# TODO(stshrive): Add parameter for template dockerfiles.
__qi_template=$(GetAbsPath "./templates/dockerfile.cuda")

__qi_application_name=$(GetContainerName "qi-c" "$__qi_provider")

function finish()
{
    unset __qi_application_name
    unset __qi_datasource
    unset __qi_provider
    unset __qi_workspace

    unset -f finish
}

trap finish EXIT

GetBuilder

Build \
    "$__qi_workspace" \
    "$__qi_application_name" \
    "$__qi_template"

if ! [ -z "$__qi_template" ]; then
    __qi_application_name=${__qi_application_name}-${__qi_template##*.}
fi

. $(dirname ${BASH_SOURCE[0]})/bin/deploy \
    ${__qi_application_name} \
    ${__qi_provider} \
    ${__qi_datasource}

if ! typeset -f ConnectToServer >/dev/null; then
    echo "An error occurred during deployment and no Jupyter server was found." >&2
    exit 1
fi

if [ ! -z ${__qi_provider/local/} ]; then
    echo
    echo "*** USE THE FOLLOWING URL TO CONNECT TO YOUR JUPYTER SERVER ***"
    echo ${JUPYTER_SERVER}:8888
    echo
    read -n 1 -p "PRESS ENTER TO CONTINUE AND RETRIEVE YOUR TOKEN" input
    echo

    trap \
        'echo "\nTerminating connection to host. Server will continue running remotely"' SIGINT
fi

ConnectToServer
