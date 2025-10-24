#!/bin/bash
# filepath: /usr/local/bin/go.sh

scripts=(
    "k2c"
    "nxc2imp" 
    "parselocker"
    "rc4"
    "nxc_users"
    "certiparse"
)

# Find the scripts directory
script_dir=""
if [[ -d "/workspace/scripts" ]]; then
    script_dir="/workspace/scripts"
elif [[ -d "/workspace" ]]; then
    script_dir="/workspace"
else
    echo "Error: Cannot find scripts directory"
    exit 1
fi

local_bin="/usr/local/bin"

echo "Looking for scripts in: $script_dir"

for script in "${scripts[@]}"
do
    if [[ -f "$script_dir/$script" ]]; then
        cp "$script_dir/$script" "$local_bin"
        echo "Copied $script to $local_bin"
    else
        echo "Warning: $script not found in $script_dir"
    fi
done

for script in "${scripts[@]}"
do
    if [[ -f "$local_bin/$script" ]]; then
        chmod +x "$local_bin/$script"
        echo "$script => $(which $script)"
    else
        echo "$script => not found"
    fi
done