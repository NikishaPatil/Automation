#!/bin/bash

ERRATA_ID=$1

function get_errata_builds() {
    # Extracting nvr's from errata
    errata_output=$(curl -s --user ':' --negotiate https://errata.devel.redhat.com/api/v1/erratum/$ERRATA_ID/builds.json | jq -r '.["RHEL-8-OSE-Middleware"].builds[][].nvr')
} 

function assign_nvr() {
    operator_nvr=$(echo "$1" | grep -w "operator-container")
    bundle_nvr=$(echo "$1" | grep -w "operator-bundle" )
    kafkasql_nvr=$(echo "$1" | grep -w "kafkasql" )
    sql_nvr=$(echo "$1" | grep -w "sql")
    
    echo "Operator NVR: $operator_nvr"
    echo "Bundle NVR: $bundle_nvr"
    echo "Kafka SQL NVR: $kafkasql_nvr"
    echo "SQL NVR: $sql_nvr"
}

function get_operator_brew_build() {

    # Getting build info from brew
    operator_build_output=$(brew call getBuild $1 --json-output)
}

function get_sql_brew_build() {

    # Getting build info from brew
    sql_build_output=$(brew call getBuild $1 --json-output)
}
function get_kafkasql_brew_build() {

    # Getting build info from brew
    kafkasql_build_output=$(brew call getBuild $1 --json-output)
}

function get_bundle_brew_build() {

    # Getting build info from brew
    bundle_build_output=$(brew call getBuild $1 --json-output)
}

function get_bundle_sha() {
    #Extracting sha value from the bundle image 

    bundle_kafkasql_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[0].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
    echo "The sha value of kafkasql in bundle image  is : $bundle_kafkasql_sha" 

    bundle_operator_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[1].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
    echo "The sha value of operator in bundle image is : $bundle_operator_sha"

    bundle_sql_sha=$(echo "$bundle_build_output" | jq -r '.extra.image.operator_manifests.related_images.pullspecs[2].new' |  sed 's/.*:\([a-f0-9]\{64\}\)$/\1/')
    echo "The sha value of sql in bundle image is : $bundle_sql_sha"
}

function get_sha() {

    #Extracting sha value from kafka-sql image 
    kafkasql_sha=$(echo "$kafkasql_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
    echo "The sha value of kafkasql is : $kafkasql_sha"

    #Extracting sha value from operator image 
    operator_sha=$(echo "$operator_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"' | cut -d ":" -f 2)
    echo "The sha value of operator is : $operator_sha"


    #Extracting sha value from sql image 
    sql_sha=$(echo "$sql_build_output" | jq -r '.extra.image.index.digests."application/vnd.docker.distribution.manifest.list.v2+json"'  | cut -d ":" -f 2)
    echo "The sha value of sql is : $sql_sha"

}

function sha_check(){

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
   
}


main() {

    get_errata_builds $ERRATA_ID
    echo "Fetching nvr from errata"
    assign_nvr "$errata_output"

    get_operator_brew_build "$operator_nvr" 
    get_sql_brew_build "$sql_nvr"
    get_bundle_brew_build "$bundle_nvr"
    get_kafkasql_brew_build "$kafkasql_nvr"

    get_bundle_sha
    get_sha

    sha_check


}

main $1






