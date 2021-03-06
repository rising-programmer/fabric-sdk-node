#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi

starttime=$(date +%s)

# Endorsement policy:
ENDORSEMENT_POLICY_TRACE=$(cat ../endorsement-policy-trace.json | tr "\n" " ")
ENDORSEMENT_POLICY_SUPERVISION=$(cat ../endorsement-policy-supervision.json | tr "\n" " ")

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  ./init.sh -l golang|node"
  echo "    -l <language> - chaincode language (defaults to \"golang\")"
}
# Language defaults to "golang"
LANGUAGE="golang"

# Parse commandline args
while getopts "h?l:" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    l)  LANGUAGE=$OPTARG
    ;;
  esac
done

##set chaincode path
function setChaincodePath(){
	LANGUAGE=`echo "$LANGUAGE" | tr '[:upper:]' '[:lower:]'`
	case "$LANGUAGE" in
		"golang")
		CC_NAME="trace"
		CC_VERSION="v0"
		CC_SRC_PATH="github.com/chaincode/go"
		CC_META_PATH="artifacts/META-INF"
		;;
		"node")
		CC_SRC_PATH="$PWD/artifacts/src/github.com/chaoncode/node"
		CC_META_PATH="$PWD/artifacts/src/github.com/chaoncode/node/META-INF/statedb/couchdb/indexes"
		;;
		*) printf "\n ------ Language $LANGUAGE is not supported yet ------\n"$
		exit 1
	esac
}

##set chaincode path
function setSupervisionChaincodePath(){
	LANGUAGE=`echo "$LANGUAGE" | tr '[:upper:]' '[:lower:]'`
	case "$LANGUAGE" in
		"golang")
		CC_NAME="supervision"
		CC_VERSION="v0"
		CC_SRC_PATH="github.com/chaincode/go"
		CC_META_PATH=""
		;;
		"node")
		CC_SRC_PATH="$PWD/artifacts/src/github.com/chaoncode/node"
		CC_META_PATH="$PWD/artifacts/src/github.com/chaoncode/node/META-INF/statedb/couchdb/indexes"
		;;
		*) printf "\n ------ Language $LANGUAGE is not supported yet ------\n"$
		exit 1
	esac
}

setChaincodePath

echo "POST request Enroll on Org1  ..."
echo
ORG1_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=doc&orgName=Org1')
echo ${ORG1_TOKEN}
ORG1_TOKEN=$(echo ${ORG1_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG1 token is $ORG1_TOKEN"
echo

echo "POST request Join channel on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer1.org1.example.com"]
}'
echo
echo

echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer1.org1.example.com\"],
	\"chaincodeName\":\"$CC_NAME\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"metadataPath\":\"$CC_META_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"$CC_VERSION\"
}"
echo
echo

setSupervisionChaincodePath

echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer1.org1.example.com\"],
	\"chaincodeName\":\"$CC_NAME\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"metadataPath\":\"$CC_META_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"$CC_VERSION\"
}"
echo
echo

echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
