#!/bin/bash

ERRATA_ID=$1

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


# Check if ERRATA_ID is provided as input and is an integer
if [ $# -ne 1 ] || ! [[ $1 =~ ^[0-9]{6}$ ]]; then
    echo "Please provide ERRATA_ID as a valid 6-digit integer argument."
    exit 1
fi


##main


# Extracting nvr's from errata
errata_payload=$(curl -sf --user ':' --negotiate https://errata.devel.redhat.com/api/v1/erratum/$ERRATA_ID/builds.json)
if [ $? -ne 0 ]; then
    echo "Error fetching errata payload"
    exit 1
fi
# Initialize an empty array to store the NVRs
nvr_array=()
nvr_array=($(echo $errata_payload | jq -r '.["RHEL-8-OSE-Middleware"].builds[][].nvr'))


# Getting build info from brew API and Extracting sha value
for nvr in "${nvr_array[@]}"
do
    #operator
    if [[ $nvr == *"operator-container"* ]]; then
        operator_build_output=$(brew call getBuild $nvr --json-output)
        operator_sha=$(echo "$operator_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
        echo "The sha value of operator is : $operator_sha "


    #kafkasql
    elif [[ $nvr == *"kafkasql"* ]]; then
        kafkasql_build_output=$(brew call getBuild $nvr --json-output)
        kafkasql_sha=$(echo "$kafkasql_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
        echo "The sha value of kafkasql is :  $kafkasql_sha "

    
    #sql
    elif [[ $nvr == *"sql"* ]]; then
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


# SHA check
if [ "$bundle_kafkasql_sha" == "$kafkasql_sha" ]; then
    echo "SHA for Kafkasql image matches"
  else
    echo "SHA for Kafkasql image does not match"
  fi

  if [ "$bundle_operator_sha" == "$operator_sha" ]; then
    echo "SHA for Operator image matches"
  else
    echo "SHA for Operator image does not match"
  fi

  if [ "$bundle_sql_sha" == "$sql_sha" ]; then
    echo "SHA for SQL image matches"
  else
    echo "SHA for SQL image does not match"
  fi





