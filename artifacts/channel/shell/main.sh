#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script extends the Hyperledger Fabric By Your First Network by
# adding a third organization to the network previously setup in the
# BYFN tutorial.
#

# prepending $PWD/../bin to PATH to ensure we are picking up the correct binaries
# this may be commented out to resolve installed version of tools if desired
export PATH=${PWD}/../bin:${PWD}:$PATH
export GOPATH=${PWD}/../../:$GOPATH
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=../config

# orgname numberic
export ORG_NAME_NUMBER=10
# orgname
export ORG_NAME="Org${ORG_NAME_NUMBER}"
# orgname lowercase
export ORG_NAME_LOWERCASE="org${ORG_NAME_NUMBER}"
# chaincode version
export CHAINCODE_VERSION="v1.${ORG_NAME_NUMBER}"
# orderer ca
export ORDERER_CA=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
. scripts/utils.sh

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  main.sh up|down|restart|generate [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-s <dbtype>]"
  echo "  main.sh -h|--help (print this message)"
  echo "    <mode> - one of 'up', 'down', 'restart' or 'generate'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "    -c <channel name> - channel name to use (defaults to \"mychannel\")"
  echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 10)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -f <docker-compose-file> - specify which docker-compose file use (defaults to docker-compose-cli.yaml)"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -l <language> - the chaincode language: golang (default) or node"
  echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
  echo
  echo "Typically, one would first generate the required certificates and "
  echo "genesis block, then bring up the network. e.g.:"
  echo
  echo "	main.sh generate -c mychannel"
  echo "	main.sh up -c mychannel -s couchdb"
  echo "	main.sh up -l node"
  echo "	main.sh down -c mychannel"
  echo
  echo "Taking all defaults:"
  echo "	main.sh generate"
  echo "	main.sh up"
  echo "	main.sh down"
}

# Ask user for confirmation to proceed
function askProceed () {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
    y|Y|"" )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      askProceed
    ;;
  esac
}

# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
function clearContainers () {
  CONTAINER_IDS=$(docker ps -aq)
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# TODO list generated image naming patterns
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Generate the needed certificates, the genesis block and start the network.
function networkUp () {

   # generate yaml through template
    cp configtx-template.yaml configtx.yaml
    cp crypto-config-template.yaml crypto-config.yaml
    CURRENT_DIR=$PWD

    cd ${CURRENT_DIR}
    sed ${OPTS} "s/ORG_NAME_LOWERCASE/${ORG_NAME_LOWERCASE}/g" configtx.yaml
    sed ${OPTS} "s/ORG_NAME/${ORG_NAME}/g" configtx.yaml
    sed ${OPTS} "s/ORG_NAME_LOWERCASE/${ORG_NAME_LOWERCASE}/g" crypto-config.yaml
    sed ${OPTS} "s/ORG_NAME/${ORG_NAME}/g" crypto-config.yaml
    cd -

    if [ -d "../crypto-config/peerOrganizations/org${ORG_NAME_NUMBER}.example.com" ];then
        echo "ERROR !!!! ORG${ORG_NAME_NUMBER} materials has exits "
        exit 1
    fi
    rm -rf crypto-config
  # generate artifacts if they don't exist
  if [ ! -d "crypto-config" ]; then
    generateCerts
    generateChannelArtifacts
    createConfigTx
    #copy material
    rm -rf ../crypto-config/peerOrganizations/org${ORG_NAME_NUMBER}.example.com
    cp -r crypto-config/peerOrganizations/org${ORG_NAME_NUMBER}.example.com ../crypto-config/peerOrganizations/

  fi
  # start org peers
  COUCHDB_PORT="$[ORG_NAME_NUMBER -1 +5]984"
  PEER_LISTEN_PORT="$[ORG_NAME_NUMBER -1 + 7]051"
  PEER_EVENT_PORT="$[ORG_NAME_NUMBER -1 + 7]053"
  CA_PORT="$[ORG_NAME_NUMBER -1 + 7]054"
  cd ../
    sh network_setup.sh createPeerTemplate -f docker-compose-peer${ORG_NAME_NUMBER}.yaml -o org${ORG_NAME_NUMBER} -M Org${ORG_NAME_NUMBER}MSP -p peer0.org${ORG_NAME_NUMBER}.example.com -c couchdb${ORG_NAME_NUMBER} -P ${COUCHDB_PORT} -l ${PEER_LISTEN_PORT} -e ${PEER_EVENT_PORT}
    sh network_setup.sh up -f docker-compose-peer${ORG_NAME_NUMBER}.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org${ORG_NAME_NUMBER}.yaml -o org${ORG_NAME_NUMBER}.example.com -P ${CA_PORT}
    sh network_setup.sh up -f docker-compose-ca-org${ORG_NAME_NUMBER}.yaml
  cd -

  echo
  echo "###############################################################"
  echo "############### Have Org${ORG_NAME_NUMBER} peers join network ##################"
  echo "###############################################################"
  scripts/step2org.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to have Org${ORG_NAME_NUMBER} peers join network"
    exit 1
  fi
  echo
  echo "###############################################################"
  echo "##### Upgrade chaincode to have Org${ORG_NAME_NUMBER} peers on the network #####"
  echo "###############################################################"
  scripts/step3org.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to add Org${ORG_NAME_NUMBER} peers on network"
    exit 1
  fi
}

# Tear down running network
function networkDown () {
  docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_ORG down --volumes
  docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_ORG -f $COMPOSE_FILE_COUCH down --volumes
  # Don't remove containers, images, etc if restarting
  if [ "$MODE" != "restart" ]; then
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config ./org3-artifacts/crypto-config/ channel-artifacts/org3.json
    # remove the docker-compose yaml file that was customized to the example
    rm -f docker-compose-e2e.yaml
  fi

  # For some black-magic reason the first docker-compose down does not actually cleanup the volumes
  docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_ORG down --volumes
  docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_ORG -f $COMPOSE_FILE_COUCH down --volumes
}

# Use the CLI container to create the configuration transaction needed to add
# Org3 to the network
function createConfigTx () {
  echo
  echo "###############################################################"
  echo "####### Generate and submit config tx to add Org${ORG_NAME_NUMBER} #############"
  echo "###############################################################"
  ./scripts/step1org.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to create config tx"
    exit 1
  fi
}

# We use the cryptogen tool to generate the cryptographic material
# (x509 certs) for the new org.  After we run the tool, the certs will
# be parked in the BYFN folder titled ``crypto-config``.

# Generates Org3 certs using cryptogen tool
function generateCerts (){
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "###############################################################"
  echo "##### Generate Org certificates using cryptogen tool #########"
  echo "###############################################################"

  (
   set -x
   cryptogen generate --config=crypto-config.yaml
   res=$?
   set +x
   if [ $res -ne 0 ]; then
     echo "Failed to generate certificates..."
     exit 1
   fi
  )
  echo
}

# Generate channel configuration transaction
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  echo "##########################################################"
  echo "#########  Generating Org${ORG_NAME_NUMBER} config material ###############"
  echo "##########################################################"
  (
   export FABRIC_CFG_PATH=$PWD
   set -x
   configtxgen -printOrg ${ORG_NAME}MSP > ${ORG_NAME_LOWERCASE}.json
   res=$?
   set +x
   if [ $res -ne 0 ]; then
     echo "Failed to generate Org${ORG_NAME_NUMBER} config material..."
     exit 1
   fi
  )
  echo
}

# Upgrade the network components which are at version 1.1.x to 1.2.x
# Stop the orderer and peers, backup the ledger for orderer and peers, cleanup chaincode containers and images
# and relaunch the orderer and peers with latest tag
function upgradeNetwork() {

  docker inspect -f '{{.Config.Volumes}}' orderer1.example.com | grep -q '/var/hyperledger/production'
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! This network does not appear to be using volumes for its ledgers, did you start from fabric-samples >= v1.1.x?"
    exit 1
  fi

  LEDGERS_BACKUP=./ledgers-backup

  # create ledger-backup directory
  mkdir -p $LEDGERS_BACKUP

  echo "Upgrading orderer"
  cd ../
  sh network_setup.sh init
  echo $PWD
  cd -

  ./scripts/upgrade_to_v12.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Test failed"
    exit 1
  fi
}


# If BYFN wasn't run abort
#if [ ! -d crypto-config ]; then
#  echo
#  echo "ERROR: Please, run byfn.sh first."
#  echo
#  exit 1
#fi

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform
OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
#default for delay
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# use this as the default docker-compose yaml definition
COMPOSE_FILE=docker-compose-cli.yaml
#
COMPOSE_FILE_COUCH=docker-compose-couch.yaml
# use this as the default docker-compose yaml definition
COMPOSE_FILE_ORG=docker-compose-${ORG_NAME_LOWERCASE}.yaml
#
COMPOSE_FILE_COUCH_ORG3=docker-compose-couch-org3.yaml
# use golang as the default language for chaincode
LANGUAGE=golang
# default image tag
IMAGETAG="latest"

ARCH=`uname -s | grep Darwin`
if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
else
    OPTS="-i"
fi
# Parse commandline args
if [ "$1" = "-m" ];then	# supports old usage, muscle memory is powerful!
    shift
fi
MODE=$1;shift
# Determine whether starting, stopping, restarting or generating for announce
if [ "$MODE" == "up" ]; then
  EXPMODE="Starting"
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
elif [ "$MODE" == "restart" ]; then
  EXPMODE="Restarting"
elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating certs and genesis block for"
elif [ "$MODE" == "upgrade" ]; then
  EXPMODE="upgrade fabric components"
else
  printHelp
  exit 1
fi
while getopts "h?t:d:f:s:i:p:M:c:P:l:e:f:o:" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    t)  CLI_TIMEOUT=$OPTARG
    ;;
    d)  CLI_DELAY=$OPTARG
    ;;
    f)  COMPOSE_FILE=$OPTARG
    ;;
    s)  IF_COUCHDB=$OPTARG
    ;;
    i)  IMAGETAG=$OPTARG
    ;;
    p)
    export PEER_NAME=$OPTARG
    ;;
    o)
    export ORG_NAME=$OPTARG
    ;;
    M)
    export MSP_ID=$OPTARG
    ;;
    c)
    export COUCHDB_NAME=$OPTARG
    ;;
    P)
    export COUCHDB_PORT=$OPTARG
    ;;
    l)
    export PEER_LISTEN_PORT=$OPTARG
    ;;
    e)
    export PEER_EVENT_PORT=$OPTARG
    ;;
    f)
    export COMPOSE_FILE=$OPTARG
    ;;
    ?)
    printHelp
    ::
  esac
done

# Announce what was requested

  if [ "${IF_COUCHDB}" == "couchdb" ]; then
        echo
        echo "${EXPMODE} with channel '${CHANNEL_NAME}' and CLI timeout of '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds and using database '${IF_COUCHDB}'"
  else
        echo "${EXPMODE} with channel '${CHANNEL_NAME}' and CLI timeout of '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds"
  fi
# ask for confirmation to proceed
askProceed

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  generateCerts
  generateChannelArtifacts
elif [ "${MODE}" == "restart" ]; then ## Restart the network
  networkDown
  networkUp
elif [ "${MODE}" == "upgrade" ]; then ## Restart the network
  upgradeNetwork
else
  printHelp
  exit 1
fi
