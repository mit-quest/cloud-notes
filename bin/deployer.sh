#!/bin/bash

# Deployer
# Interface for all deployment implementations
#
__QI_DEPLOYER_INTERFACE=(\
    GetPlatformContainer \
    Login \
    Provision \
    PrepareDocker \
    Deploy \
    ConnectToServer \
    CopyData\
)

function __qi_deployer_validate()
{
}
