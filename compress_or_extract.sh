#!/bin/bash

set -e

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <directory|archive.tar.xz>"
    exit 1
fi

input="$1"

if [[ "$input" == *.tar.xz ]]; then
    echo "Extracting $input ..."
    tar -xJf "$input"
elif [[ -d "$input" ]]; then
    dir="${input%/}"
    echo "Compressing $input to $dir.tar.xz with maximum compression ..."
    XZ_OPT=-9 tar -cJf "$dir.tar.xz" "$dir"
else
    echo "Input must be a directory to compress or a .tar.xz archive to extract."
    exit 2
fi
