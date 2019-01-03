#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run in the org3cli container as the
# final step of the EYFN tutorial. It simply issues a couple of
# chaincode requests through the org3 peers to check that org3 was
# properly added to the network previously setup in the BYFN tutorial.
#

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Extend your first network (EYFN) test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${TIMEOUT:="10"}
: ${LANGUAGE:="golang"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
#export ORDERER_CA=/opt/goworkspace/src/blockchain/dymatic-add-org/fabric-samples/first-network/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import functions
. scripts/utils.sh

starttime=$(date +%s)

#chaincodeQuery 0 3 90
#    if test $((i%4)) -eq 0 ; then
#            echo 4
#            continue
#    fi
#    if test $((i%3)) -eq 0 ; then
#            echo 3
#            continue
#    fi
#    if test $((i%2)) -eq 0 ; then
#            echo 2
#            continue
#    fi
#    if test $((i%1)) -eq 0 ; then
#            continue
#            echo 1
#    fi
for ((i=1; i<=100; i++))
do
    echo "===================== Invoke chaincode ${i} ===================== "

    chaincodeInvoke 0 1 1 &
done

for ((i=1; i<=100; i++))
do
    echo "===================== Invoke chaincode ${i} ===================== "
    chaincodeInvoke 0 2 2 &
done

for ((i=1; i<=120; i++))
do
    echo "===================== Invoke chaincode ${i} ===================== "
    chaincodeInvoke 0 3 1 &
done

#for ((i=1; i<=10; i++))
#do
#    echo "===================== Invoke chaincode ${i} ===================== "
#    chaincodeInvoke 0 4 2 &
#done


echo "Total execution time : $(($(date +%s)-starttime)) secs ..."

#chaincodeQuery 0 3 80

echo
echo "========= All GOOD, EYFN test execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
