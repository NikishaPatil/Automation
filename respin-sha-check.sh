#!/bin/bash

# Prompt the user to enter the number of errata IDs
read -p "Enter the number of errata IDs: " num_ids

# Initialize an empty array to store the IDs
ids=()

# Loop through the number of IDs and prompt the user to enter each ID
for (( i=1; i<=$num_ids; i++ ))
do
    read -p "Enter errata ID $i: " id
    ids+=("$id")
done

# Initialize an empty array to store the NVRs
nvr_array=()

# Loop through each ID in the array
for id in "${ids[@]}"
do
    echo "fetching NVR's from errata_id: $id"
    # Make a CURL request for the ID and pipe its output to jq to extract the nvr field from the JSON response.
    nvr=$(curl -sf --user ':' --negotiate https://errata.devel.redhat.com/api/v1/erratum/${id}/builds.json | jq -r '.["RHEL-8-OSE-Middleware"].builds[][].nvr')

    # Since the output of the jq command is a single string with newline-separated values
    # splitting it into an array using the readarray command and appending it to the nvr_array
    readarray -t temp_nvr_array <<<"$nvr"
    nvr_array+=("${temp_nvr_array[@]}")
done

# Print the length of the nvr_array and all the elements in separate lines
echo "length=${#nvr_array[@]}"
printf '%s\n' "${nvr_array[@]}"

