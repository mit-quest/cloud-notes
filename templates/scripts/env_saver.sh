#!/bin/bash

_ENV_SEARCH="$1"
_SAVE_FILE="$2"

if [[ "$_ENV_SEARCH" = "*" ]]; then
    while  IFS= read -r line; do
        _ENV_SEARCH="${line/=*/}\\|"
    done < <(printenv)
fi

while IFS= read -r line; do
    _variable=${line/=*/}
    _value=${line#*=}

    if [[ $_value == *":"* || $_variable == *"PATH"* ]]; then
        echo "export ${_variable}=\"$_value:\$${_variable}\"" >> $_SAVE_FILE;
    else
        echo "export ${_variable}=\"$_value\"" >> $_SAVE_FILE;
    fi
done < <(printenv | grep $_ENV_SEARCH)
