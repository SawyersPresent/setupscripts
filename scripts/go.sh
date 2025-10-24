#!/bin/bash

scripts=(
    "k2c"
    "nxc2imp"
    "parselocker"
    "rc4"
    "nxc_users"
    "certiparse"
)

local_bin="/usr/local/bin"

for script in "${scripts[@]}"
do
    cp "$script" "$local_bin"
done

for script in "${scripts[@]}"
do
    chmod +x "$local_bin/$script"
    echo "$script => $(which $script)"
done