#!/bin/bash

if [ ! -x "$(command -v docker)" ]; then
    echo "\
An installation of docker is required. \
See https://docs.docker.com/install for installation instructions."

    exit 1
fi


function IsWindows()
{
    if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
        echo true
    else
        echo false
    fi

    return 0
}
