#!/bin/bash

# Deployer
# Interface for all deployment implementations
#
__QI_BUILDER_INTERFACE=(\
    Build \
    CheckDataSource \
    CheckWorkspace \
    GetBuilder \
)

function __qi_builder_validate()
{
}
