#!/bin/bash

# Check if user has a valid Kerberos ticket
if ! klist -s; then 
  # If not, print error message and exit
  echo "Please have a valid Kerberos ticket, you need to run ' kinit $USER ' and enter your Kerberos password"
  exit -1 
fi


# Check if rhpkg package is installed
if ! rpm -q rhpkg > /dev/null ; then 
  echo "brew package not installed. Please install it with 'sudo dnf install rhpkg'"
  exit -1 
fi


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
    # Extracting nvr's from errata
    errata_payload=$(curl -sf --user ':' --negotiate https://errata.devel.redhat.com/api/v1/erratum/${id}/builds.json | jq -r '.["RHEL-8-OSE-Middleware"].builds[][].nvr' 2> /dev/null)
    if [ $? -ne 0 ]; then
        echo "Error fetching errata payload"
        exit 1
    fi


    # Since the output of the jq command is a single string with newline-separated values
    # splitting it into an array using the readarray command and appending it to the nvr_array
    readarray -t temp_nvr_array <<<"$errata_payload"
    nvr_array+=("${temp_nvr_array[@]}")
done

# Print the length of the nvr_array and all the elements in separate lines
echo "length=${#nvr_array[@]}"
printf '%s\n' "${nvr_array[@]}"



# Check if "operator-bundle" exists in the nvr_array
if [[ ! " ${nvr_array[@]} " =~ "operator-bundle" ]]; then
  echo "There was no respin for the operator bundle image"
else
  # Initialize variables to store SHA values
  bundle_kafkasql_sha=""
  bundle_operator_sha=""
  bundle_sql_sha=""
  kafkasql_sha=""
  sql_sha=""
  
  for nvr in "${nvr_array[@]}"
  do
    # operator
    if [[  $nvr == *"operator-container"* ]]; then
      operator_build_output=$(brew call getBuild $nvr --json-output)
      operator_sha=$(echo "$operator_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
      echo "The sha value of operator is: $operator_sha"


    # kafkasql
    elif [[ $nvr == *"kafkasql"* ]]; then
        kafkasql_build_output=$(brew call getBuild $nvr --json-output)
        kafkasql_sha=$(echo "$kafkasql_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
        echo "The sha value of kafkasql is : $kafkasql_sha "

    #sql
    elif [[  $nvr == *"sql"* ]]; then
        sql_build_output=$(brew call getBuild $nvr --json-output)
        sql_sha=$(echo "$sql_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
        echo "The sha value of sql is : $sql_sha "

    #bundle
    elif [[ $nvr == *"operator-bundle"* ]]; then
        bundle_build_output=$(brew call getBuild $nvr --json-output)

        bundle_kafkasql_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[0].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
        echo "The sha value of kafkasql in bundle image is : $bundle_kafkasql_sha "

        bundle_operator_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[1].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
        echo "The sha value of operator in bundle image is : $bundle_operator_sha"
        
        bundle_sql_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[2].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
        echo "The sha value of sql in bundle image is : $bundle_sql_sha"
    fi
    done
fi

# SHA check
if [[ " ${nvr_array[@]} " =~ "operator-bundle" ]]; then
    if [ -z "$kafkasql_sha" ]; then
        echo "There was no respin for kafkasql"
    elif [ "$bundle_kafkasql_sha" == "$kafkasql_sha" ]; then
        echo "SHA for Kafkasql image matches"
    else
        echo "SHA for Kafkasql image does not match"
    fi

   
    if [ -z "$sql_sha" ]; then
        echo "There was no respin for sql"
    elif [ "$bundle_sql_sha" == "$sql_sha" ]; then
        echo "SHA for SQL image matches"
    else
        echo "SHA for SQL image does not match"
    fi

     if [ -z "$operator_sha" ]; then
        echo "There was no respin for Operator"
    elif [ "$bundle_operator_sha" == "$operator_sha" ]; then
        echo "SHA for Operator image matches"
    else
        echo "SHA for Operator image does not match"
    fi

else
    echo "Error: The nvr of operator-bundle image wasn't found in the errata payload"
fi

