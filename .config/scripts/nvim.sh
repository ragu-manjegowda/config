#!/bin/bash

###############################################################################
# Get the last argument, assume it to be dir/file for nvim to open
###############################################################################
path="${*: -1}"


###############################################################################
# If file path is relative_path change it to absolute_path
###############################################################################

# Function to get the absolute path
get_absolute_path() {
    local relative_path="$1"
    if [ -e "$relative_path" ]; then
        # Use readlink or realpath to resolve the absolute path
        # shellcheck disable=SC2005
        echo "$(readlink -f "$relative_path")"
    else
        echo "$relative_path"
    fi
}

# Check if the last argument is a relative path and convert it to absolute
if [[ "$path" != /* ]]; then
    absolute_path=$(get_absolute_path "$path")
    # Replace the last argument with the absolute path
    set -- "${@:1:$#-1}" "$absolute_path"
fi

###############################################################################
# cd to file dir
###############################################################################
if [ -d "$path" ]; then
    cd "$path" || { echo "Failed to change directory to $path"; exit 1; }
elif [ -f "$path" ]; then
    dir=$(dirname "$path")
    cd "$dir" || { echo "Failed to change directory to $dir"; exit 1; }
fi

###############################################################################
# Open nvim
###############################################################################
NVIM_BIN_PATH=/localhome/local-rmanjegowda/.remote-nvim/nvim-downloads/v0.10.1/usr/bin/nvim
NVIM_HOME=/localhome/local-rmanjegowda/.remote-nvim/workspaces/QjV4eRaSdV

XDG_CONFIG_HOME=$NVIM_HOME/.config XDG_DATA_HOME=$NVIM_HOME/.local/share \
    XDG_STATE_HOME=$NVIM_HOME/.local/state \
    XDG_CACHE_HOME=$NVIM_HOME/.cache NVIM_APPNAME="nvim" $NVIM_BIN_PATH "$@"
