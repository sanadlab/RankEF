#!/bin/bash

start=-1
end=-1

# this loop iterates over all missing ids and collapses them into ranges
# missing ids are sorted numerically
# Example: 1,2,3,5,6,8 -> 1-3,5-6,8-8
{
    while read -r missing_id; do
        if [[ $start -eq -1 ]]; then
            start=$missing_id
            end=$missing_id
        elif [[ $((missing_id - end)) -eq 1 ]]; then
            end=$missing_id
        else
            echo "$start-$end"
            start=$missing_id
            end=$missing_id
        fi
    done < <(grep -xvf <(ls dataset_construction/ | xargs -I@ basename @ ".json" | sort -n) <(seq 0 4999))
    # Print the last range if any IDs were processed
    if [[ $start -ne -1 ]]; then
        echo "$start-$end"
    fi
} | paste -sd,
