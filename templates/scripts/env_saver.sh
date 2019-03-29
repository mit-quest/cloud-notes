#!/bin/bash

_ENV_SEARCH=$1
_SAVE_FILE=$2

while IFS= read -r line; do
    _value=${line#*=}
    _value_length=${#_value}
    _variable=${line:0:-$_value_length}
    echo "export ${_variable}\"$_value\"" >> $_SAVE_FILE; \
done < <(printenv | grep "$_ENV_SEARCH")
