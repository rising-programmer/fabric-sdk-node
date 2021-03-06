#!/usr/bin/env bash
jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi

starttime=$(date +%s)

# Endorsement policy:
ENDORSEMENT_POLICY_TRACE=$(cat ../endorsement-policy-trace.json | tr "\n" " ")

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  ./upgrade-chainocde-trace.sh -l golang|node"
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
		CC_VERSION="v2.2"
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
echo "POST request Enroll on Org2 ..."
echo
ORG2_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Barry&orgName=Org2')
echo ${ORG2_TOKEN}
ORG2_TOKEN=$(echo ${ORG2_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG2 token is $ORG2_TOKEN"
echo
echo "POST request Enroll on Org3 ..."
echo
ORG3_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Selina&orgName=Org3')
echo ${ORG3_TOKEN}
ORG3_TOKEN=$(echo ${ORG3_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG3 token is $ORG3_TOKEN"
echo
echo "POST request Enroll on Org4..."
echo
ORG4_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Randy&orgName=Org4')
echo ${ORG4_TOKEN}
ORG4_TOKEN=$(echo ${ORG4_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG4 token is $ORG4_TOKEN"
echo
echo "POST request Enroll on Org5..."
echo
ORG5_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=test5&orgName=Org5')
echo ${ORG5_TOKEN}
ORG5_TOKEN=$(echo ${ORG5_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG5 token is $ORG5_TOKEN"
echo
echo "POST request Enroll on Org6..."
echo
ORG6_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=test6&orgName=Org6')
echo ${ORG6_TOKEN}
ORG6_TOKEN=$(echo ${ORG6_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG6 token is $ORG6_TOKEN"
echo
echo "POST request Enroll on Org7..."
echo
ORG7_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=test7&orgName=Org7')
echo ${ORG7_TOKEN}
ORG7_TOKEN=$(echo ${ORG7_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG7 token is $ORG7_TOKEN"
echo
echo "POST request Enroll on Org8..."
echo
ORG8_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=test8&orgName=Org8')
echo ${ORG8_TOKEN}
ORG8_TOKEN=$(echo ${ORG8_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG8 token is $ORG8_TOKEN"
echo
echo "POST request Enroll on Org9..."
echo
ORG9_TOKEN=$(curl -s -X POST \
  http://localhost:4000/api/v1/token \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=test9&orgName=Org9')
echo ${ORG9_TOKEN}
ORG9_TOKEN=$(echo ${ORG9_TOKEN} | jq ".token" | sed "s/\"//g")
echo
echo "ORG9 token is $ORG9_TOKEN"
echo
echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.example.com\"],
	\"chaincodeName\":\"$CC_NAME\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"metadataPath\":\"$CC_META_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"$CC_VERSION\"
}"
echo
echo

echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org2.example.com\"],
	\"chaincodeName\":\"$CC_NAME\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"metadataPath\":\"$CC_META_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"$CC_VERSION\"
}"
echo
echo
#
#echo "POST Install chaincode on Org3"
#echo
#curl -s -X POST \
#  http://localhost:4000/chaincodes \
#  -H "authorization: Bearer $ORG3_TOKEN" \
#  -H "content-type: application/json" \
#  -d "{
#	\"peers\": [\"peer0.org3.example.com\"],
#	\"chaincodeName\":\"$CC_NAME\",
#	\"chaincodePath\":\"$CC_SRC_PATH\",
#	\"metadataPath\":\"$CC_META_PATH\",
#	\"chaincodeType\": \"$LANGUAGE\",
#	\"chaincodeVersion\":\"$CC_VERSION\"
#}"
#echo
#echo
#
#echo "POST Install chaincode on Org4"
#echo
#curl -s -X POST \
#  http://localhost:4000/chaincodes \
#  -H "authorization: Bearer $ORG4_TOKEN" \
#  -H "content-type: application/json" \
#  -d "{
#	\"peers\": [\"peer0.org4.example.com\"],
#	\"chaincodeName\":\"$CC_NAME\",
#	\"chaincodePath\":\"$CC_SRC_PATH\",
#	\"metadataPath\":\"$CC_META_PATH\",
#	\"chaincodeType\": \"$LANGUAGE\",
#	\"chaincodeVersion\":\"$CC_VERSION\"
#}"
#echo
#echo
#
#echo "POST Install chaincode on Org5"
#echo
#curl -s -X POST \
#  http://localhost:4000/chaincodes \
#  -H "authorization: Bearer $ORG5_TOKEN" \
#  -H "content-type: application/json" \
#  -d "{
#	\"peers\": [\"peer0.org5.example.com\"],
#	\"chaincodeName\":\"$CC_NAME\",
#	\"chaincodePath\":\"$CC_SRC_PATH\",
#	\"metadataPath\":\"$CC_META_PATH\",
#	\"chaincodeType\": \"$LANGUAGE\",
#	\"chaincodeVersion\":\"$CC_VERSION\"
#}"
#echo
#echo
#
#echo "POST Install chaincode on Org6"
#echo
#curl -s -X POST \
#  http://localhost:4000/chaincodes \
#  -H "authorization: Bearer $ORG6_TOKEN" \
#  -H "content-type: application/json" \
#  -d "{
#	\"peers\": [\"peer0.org6.example.com\"],
#	\"chaincodeName\":\"$CC_NAME\",
#	\"chaincodePath\":\"$CC_SRC_PATH\",
#	\"metadataPath\":\"$CC_META_PATH\",
#	\"chaincodeType\": \"$LANGUAGE\",
#	\"chaincodeVersion\":\"$CC_VERSION\"
#}"
#echo
#echo
#
#echo "POST Install chaincode on Org7"
#echo
#curl -s -X POST \
#  http://localhost:4000/chaincodes \
#  -H "authorization: Bearer $ORG7_TOKEN" \
#  -H "content-type: application/json" \
#  -d "{
#	\"peers\": [\"peer0.org7.example.com\"],
#	\"chaincodeName\":\"$CC_NAME\",
#	\"chaincodePath\":\"$CC_SRC_PATH\",
#	\"metadataPath\":\"$CC_META_PATH\",
#	\"chaincodeType\": \"$LANGUAGE\",
#	\"chaincodeVersion\":\"$CC_VERSION\"
#}"
#echo
#echo
#
#echo "POST Install chaincode on Org8"
#echo
#curl -s -X POST \
#  http://localhost:4000/chaincodes \
#  -H "authorization: Bearer $ORG8_TOKEN" \
#  -H "content-type: application/json" \
#  -d "{
#	\"peers\": [\"peer0.org8.example.com\"],
#	\"chaincodeName\":\"$CC_NAME\",
#	\"chaincodePath\":\"$CC_SRC_PATH\",
#	\"metadataPath\":\"$CC_META_PATH\",
#	\"chaincodeType\": \"$LANGUAGE\",
#	\"chaincodeVersion\":\"$CC_VERSION\"
#}"
#echo
#echo

#echo "POST Install chaincode on Org9"
#echo
#curl -s -X POST \
#  http://localhost:4000/chaincodes \
#  -H "authorization: Bearer $ORG9_TOKEN" \
#  -H "content-type: application/json" \
#  -d "{
#	\"peers\": [\"peer0.org9.example.com\"],
#	\"chaincodeName\":\"$CC_NAME\",
#	\"chaincodePath\":\"$CC_SRC_PATH\",
#	\"metadataPath\":\"$CC_META_PATH\",
#	\"chaincodeType\": \"$LANGUAGE\",
#	\"chaincodeVersion\":\"$CC_VERSION\"
#}"
#echo
#echo

echo "POST instantiate chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
  	\"peers\": [\"peer0.org1.example.com\"],
	\"chaincodeName\":\"$CC_NAME\",
	\"chaincodeVersion\":\"$CC_VERSION\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"endorsementPolicy\": $ENDORSEMENT_POLICY_TRACE,
	\"upgrade\":\"true\",
	\"args\":[]
}"
echo
echo