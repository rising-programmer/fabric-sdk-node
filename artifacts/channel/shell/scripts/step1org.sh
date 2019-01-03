#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run in the org3cli container as the
# first step of the EYFN tutorial.  It creates and submits a
# configuration transaction to add org3 to the network previously
# setup in the BYFN tutorial.
#

CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5

CC_SRC_PATH="github.com/chaincode/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

# import utils
. scripts/utils.sh

echo
echo "========= Creating config transaction to add org3 to network =========== "
echo

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi

# set peer env
setGlobals 0 1

# Fetch the config for the channel, writing it to config.json
fetchChannelConfig ${CHANNEL_NAME} config.json

# Modify the configuration to append the new org
set -x
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"'${ORG_NAME}'MSP":.[1]}}}}}' config.json ${ORG_NAME_LOWERCASE}.json > modified_config.json
set +x

# Compute a config update, based on the differences between config.json and modified_config.json, write it as a transaction to ${ORG_NAME_LOWERCASE}_update_in_envelope.pb
createConfigUpdate ${CHANNEL_NAME} config.json modified_config.json ${ORG_NAME_LOWERCASE}_update_in_envelope.pb

echo
echo "========= Config transaction to add ${ORG_NAME_LOWERCASE} to network created ===== "
echo

echo "Signing config transaction"
echo
for ((i=1; i<=$[ORG_NAME_NUMBER -1]; i++))
do
    signConfigtxAsPeerOrg $i ${ORG_NAME_LOWERCASE}_update_in_envelope.pb
done

echo
echo "========= Submitting transaction from a different peer (peer0.org2) which also signs it ========= "
echo
setGlobals 0 1
set -x
peer channel update -f ${ORG_NAME_LOWERCASE}_update_in_envelope.pb -c ${CHANNEL_NAME} -o orderer1.example.com:7050 --tls --cafile ${ORDERER_CA}
set +x

echo
echo "========= Config transaction to add ${ORG_NAME_LOWERCASE} to network submitted! =========== "
echo

exit 0
