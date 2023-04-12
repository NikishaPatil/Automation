#!/bin/bash

ERRATA_ID=$1

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
nvr=($(echo $errata_payload | jq -r '.["RHEL-8-OSE-Middleware"].builds[][].nvr'))


# Getting build info from brew and Extracting value of image tag 
for nvr_value in "${nvr[@]}"
do
    #operator
    if [[ $nvr_value == *"operator-container"* ]]; then
        operator_build_output=$(brew call getBuild $nvr_value --json-output)
        operator=$(echo $operator_build_output | jq -r '.extra.image.index.pull[1]' | sed 's/registry-proxy\.engineering\.redhat\.com/brew.registry.redhat.io/')
        echo $operator

    #kafkasql
    elif [[ $nvr_value == *"kafkasql"* ]]; then
        kafkasql_build_output=$(brew call getBuild $nvr_value --json-output)
        kafkasql=$(echo $kafkasql_build_output | jq -r '.extra.image.index.pull[1]' | sed 's/registry-proxy\.engineering\.redhat\.com/brew.registry.redhat.io/')
        echo $kafkasql 

    #sql
    elif [[ $nvr_value == *"sql"* ]]; then
        sql_build_output=$(brew call getBuild $nvr_value --json-output)
        sql=$(echo $sql_build_output | jq -r '.extra.image.index.pull[1]' | sed 's/registry-proxy\.engineering\.redhat\.com/brew.registry.redhat.io/')
        echo $sql 

    #bundle
    elif [[ $nvr_value == *"operator-bundle"* ]]; then
        bundle_build_output=$(brew call getBuild $nvr_value --json-output)
        bundle=$(echo $bundle_build_output | jq -r '.extra.image.index.pull[1]' | sed 's/registry-proxy\.engineering\.redhat\.com/brew.registry.redhat.io/')
        echo $bundle 
    
    fi

done
    







