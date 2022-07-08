#!/bin/bash

function prepData() {

	URL="https://localhost/mgmt/tm/asm/policies/$POLICYID/urls"
	JSON_DATA='{"name": "'$1'", "protocol": "https", "description": "Added_via_allowedURLs_script", "performStaging": "false"}'
	echo $JSON_DATA
#	sendRequest $URL $JSON_DATA
	sendRequest $URL $1
}

function sendRequest(){
	echo "[*] Adding: "$2" for policy ID:$POLICYID"
	curl -sku $USERF5:$PASSWORD -X POST $1 --data '{ "name": "'$2'", "protocol": "https", "description": "Added_via_allowedURLs_script", "performStaging": "false" }' |jq .
	prepApplyData
}

function prepApplyData() {
	URL_APPLY="https://localhost/mgmt/tm/asm/tasks/apply-policy"
	JSON_DATA='{"policyReference": {"link": "https://localhost/mgmt/tm/asm/policies/$POLICYID"}}'
	applyPolicy $URL_APPLY $JSON_DATA
}

function applyPolicy(){
	curl -sku "$USERF5":"$PASSWORD" -X POST "$1" --data '"$2"' | jq .
}

function checkArgs(){
    if [[ -z $1 ]]; then
        echo "Missing arguments"
        exit 1;
    fi
}

#Function to read file lines
function readFile() {
     checkArgs $POLICYID
     checkArgs $USERF5
     checkArgs $PASSWORD
		
    if [[ -f $FILE ]]; then
        while read line; do
            echo "[*]Preparing request for $line"
	    prepData $line
        done < $FILE
    else
        echo "The file specified does not exists"
		exit 1
    fi
}

#Parsing arguments
for i in "$@"; do
    case $i in
        -i=*|--input=*)
            FILE="${i#*=}"
			checkArgs $FILE
            shift
            ;;
        -p=*|--policy=*)
            POLICYID="${i#*=}"
			checkArgs $POLICYID
            shift
            ;;
        -u=*|--user=*)
            USERF5="${i#*=}"
			checkArgs $USERF5
            shift
            ;;
        -c=*|--password=*)
            PASSWORD="${i#*=}"
			checkArgs $PASSWORD
            shift
            ;;
        -h|--help)
            echo "Usage: -i=<input file> -p=policy id> -u=<user F5> -c=<password F5>"
			exit 1
            ;;						
        -*|--*)
            echo "Uknown option $i"
            exit 1
            ;;
        *)
            ;;
    esac
done

readFile

