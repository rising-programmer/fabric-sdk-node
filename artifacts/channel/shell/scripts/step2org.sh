#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run in the org3cli container as the
# second step of the EYFN tutorial. It joins the org3 peers to the
# channel previously setup in the BYFN tutorial and install the
# chaincode as version 2.0 on peer0.org3.
#

echo
echo "========= Getting Org${ORG_NAME_NUMBER} on to your first network ========= "
echo
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

CC_SRC_PATH="github.com/example/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

# import utils
. scripts/utils.sh

setGlobals 0 ${ORG_NAME_NUMBER} 1

echo "Fetching channel config block from orderer..."
set -x
peer channel fetch 0 $CHANNEL_NAME.block -o orderer1.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA >&log.txt
res=$?
set +x
cat log.txt
verifyResult $res "Fetching config block from orderer has Failed"

echo "===================== Having peer0.org${ORG_NAME_NUMBER} join the channel ===================== "
joinChannelWithRetry 0 ${ORG_NAME_NUMBER}
echo "===================== peer0.org${ORG_NAME_NUMBER} joined the channel \"$CHANNEL_NAME\" ===================== "
#echo "Installing chaincode ${CHAINCODE_VERSION} on peer0.org${ORG_NAME_NUMBER}..."
#installChaincode 0 ${ORG_NAME_NUMBER} ${CHAINCODE_VERSION}

echo
echo "========= Got Org${ORG_NAME_NUMBER} halfway onto your first network ========= "
echo

exit 0
