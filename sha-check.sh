#!/bin/bash

ERRATA_ID=$1

##main


# Extracting nvr's from errata
errata_payload=$(curl -s --user ':' --negotiate https://errata.devel.redhat.com/api/v1/erratum/$ERRATA_ID/builds.json)
nvr=($(echo $errata_payload | jq -r '.["RHEL-8-OSE-Middleware"].builds[][].nvr'))

# Assigning nvr values to variables
operator_nvr=$(echo "$nvr" | grep -w "operator-container")
bundle_nvr=$(echo "$nvr" | grep -w "operator-bundle" )
kafkasql_nvr=$(echo "$nvr" | grep -w "kafkasql" )
sql_nvr=$(echo "$nvr" | grep -w "sql")


# Getting build info from brew
operator_build_output=$(brew call getBuild $operator_nvr --json-output)
sql_build_output=$(brew call getBuild $sql_nvr --json-output)
kafkasql_build_output=$(brew call getBuild $kafkasql_nvr --json-output)
bundle_build_output=$(brew call getBuild $bundle_nvr --json-output)


#Extracting sha value from the bundle image 
bundle_kafkasql_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[0].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
echo "The sha value of kafkasql in bundle image  is : $bundle_kafkasql_sha" 

bundle_operator_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[1].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
echo "The sha value of operator in bundle image is : $bundle_operator_sha"

bundle_sql_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[2].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
echo "The sha value of sql in bundle image is : $bundle_sql_sha"


# Extracting sha value from kafka-sql image
kafkasql_sha=$(echo "$kafkasql_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
echo "The sha value of kafkasql is : $kafkasql_sha"

# Extracting sha value from operator image
operator_sha=$(echo "$operator_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
echo "The sha value of operator is : $operator_sha"

# Extracting sha value from sql image
sql_sha=$(echo "$sql_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
echo "The sha value of sql is : $sql_sha"


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


