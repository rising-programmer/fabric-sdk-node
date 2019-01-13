#!/usr/bin/env bash

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  network_setup.sh <mode> [-p <peer-name>] [-o <org-name>][-M <msp-id>][-c <couchdb-name>] [-P <couchdb-port>] [-f <docker-compose-file-name>] [-l <peer-listen-port>] [-e <peer-event-port>] "
  echo "    <mode> - one of 'up', 'down', 'restart', 'generate' or 'upgrade'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "      - 'upgrade'  - upgrade the network from version 1.1.x to 1.2.x"
  echo "    -p <peer name> - peer name"
  echo "    -o <org name> - org name"
  echo "    -M <msp id> - msp id"
  echo "    -c <couchdb name> - couchdb name "
  echo "    -P <couchdb port> - couchdb port"
  echo "    -f <docker-compose-file-name> - specify which docker-compose file name use "
  echo "    -l <peer listen port> - peer listen port"
  echo "    -e <peer event port> - peer event port"
  echo "  network_setup.sh -h (print this message)"
  echo
  echo "e.g.:"
  echo
  echo "sh network_setup.sh createPeerTemplate -p peer0.org1.example.com -o org1 -M Org1Msp -c couchdb -P 5984 -l 7051 -e 7053 -f docker-composer-peer1.yaml"
  echo
}
IMAGETAG="1.4"

function networkUp(){
    if [ -z ${COMPOSE_FILE} ];then
        printHelp
        exit 0
    else
       IMAGE_TAG=${IMAGETAG} docker-compose -f ../${COMPOSE_FILE} up -d
    fi
}

function networkDown() {
    if [ -z ${COMPOSE_FILE} ];then
        CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
            docker rm -f ${CONTAINER_IDS}
        fi

    else
        docker-compose -f ../${COMPOSE_FILE} down --volumns
    fi

    if [ -d "crypto-config" ] ;then
        rm -rf crypto-config
    fi

    rm -rf /tmp/fabric-client-kv-org*

    rm -rf ../../fabric-client-kv-org*

    rm -rf ../../mount/*

    rm -rf ../*.yamlt

    rm -rf ../docker-compose.yaml
    rm -rf ../docker-compose-ca.yaml
    rm -rf ../docker-compose-peer1.yaml
    rm -rf ../docker-compose-peer2.yaml
    rm -rf ../docker-compose-peer3.yaml
    rm -rf ../docker-compose-peer4.yaml
    rm -rf ./genesis.block
    rm -rf ./mychannel.tx
    rm -rf ./Org1MSPanchors.tx
    rm -rf ./Org2MSPanchors.tx
}

## create peer template
function createPeerTemplate(){
    if [ -z ${COMPOSE_FILE} ] || [ -z ${ORG_NAME} ] || [ -z ${MSP_ID} ] || [ -z ${PEER_NAME} ] || [ -z ${COUCHDB_NAME} ] || [ -z ${COUCHDB_PORT} ] || [ -z ${PEER_LISTEN_PORT} ]|| [ -z ${PEER_EVENT_PORT} ]; then
     printHelp
    else
        ARCH=`uname -s | grep Darwin`
        if [ "$ARCH" == "Darwin" ]; then
            OPTS="-it"
        else
            OPTS="-i"
        fi

        cp ../docker-compose-peer-template.yaml ../${COMPOSE_FILE}

        CURRENT_DIR=$PWD

        cd ${CURRENT_DIR}
        sed ${OPTS} "s/PEER_NAME/${PEER_NAME}/g" ../${COMPOSE_FILE}
        sed ${OPTS} "s/COUCHDB_NAME/${COUCHDB_NAME}/g" ../${COMPOSE_FILE}
        sed ${OPTS} "s/COUCHDB_PORT/${COUCHDB_PORT}/g" ../${COMPOSE_FILE}
        sed ${OPTS} "s/MSP_ID/${MSP_ID}/g" ../${COMPOSE_FILE}
        sed ${OPTS} "s/PEER_LISTEN_PORT/${PEER_LISTEN_PORT}/g" ../${COMPOSE_FILE}
        sed ${OPTS} "s/PEER_EVENT_PORT/${PEER_EVENT_PORT}/g" ../${COMPOSE_FILE}
        sed ${OPTS} "s/ORG_NAME/${ORG_NAME}/g" ../${COMPOSE_FILE}
        fi

        cd -
}

## create ca template
function createCATemplate(){
    if [ -z ${COMPOSE_FILE} ] || [ -z ${ORG_NAME} ] || [ -z ${COUCHDB_PORT} ]; then
     printHelp
    else
        ARCH=`uname -s | grep Darwin`
        if [ "$ARCH" == "Darwin" ]; then
            OPTS="-it"
        else
            OPTS="-i"
        fi

        cp ../docker-compose-ca-template.yaml ../${COMPOSE_FILE}

        CURRENT_DIR=$PWD

        cd crypto-config/peerOrganizations/${ORG_NAME}/ca
        PRIV_KEY=$(ls *_sk)
        cd ${CURRENT_DIR}
        sed ${OPTS} "s/CA_PRIVATE_KEY/${PRIV_KEY}/g" ../${COMPOSE_FILE}
        sed ${OPTS} "s/ORG_NAME/${ORG_NAME}/g" ../${COMPOSE_FILE}
        sed ${OPTS} "s/PORT/${COUCHDB_PORT}/g" ../${COMPOSE_FILE}
        fi

        cd -
}

## update network config
function updateNetworkConfiguration(){
    ARCH=`uname -s | grep Darwin`
    if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
    else
        OPTS="-i"
    fi

    CURRENT_DIR=$PWD
    cp ../network-config-template.yaml ../network-config.yaml

for ((i=1;i<10000;i++))
do
    if [ ! -d "crypto-config/peerOrganizations/org${i}.example.com" ]; then
        break
    fi
    cd crypto-config/peerOrganizations/org${i}.example.com/users/Admin@org${i}.example.com/msp/keystore
    PRIV_KEY=$(ls *_sk)
    cd ${CURRENT_DIR}
    sed ${OPTS} "s/CA${i}_PRIVATE_KEY/${PRIV_KEY}/g" ../network-config.yaml
done
}

function dcrm(){
   docker rm -f $(docker ps -aq)
}

## 启动orderer1节点
function startOrderer1(){
    sh network_setup.sh up -f docker-orderer-kafka.yaml
}

## 启动orderer2节点
function startOrderer2(){
    sh network_setup.sh up -f docker-orderer2.yaml
}

## 启动peer1节点和ca1节点
function startPeerForOrg1(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer1.yaml -o org1 -M Org1MSP -p peer0.org1.example.com -c couchdb1 -P 5984 -l 7051 -e 7053
    sh network_setup.sh up -f docker-compose-peer1.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org1.yaml -o org1.example.com -P 7054
    sh network_setup.sh up -f docker-compose-ca-org1.yaml
}

## 启动peer2节点和ca2节点
function startPeerForOrg2(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer2.yaml -o org2 -M Org2MSP -p peer0.org2.example.com -c couchdb2 -P 6984 -l 8051 -e 8053
    sh network_setup.sh up -f docker-compose-peer2.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org2.yaml -o org2.example.com -P 8054
    sh network_setup.sh up -f docker-compose-ca-org2.yaml
}

## 启动peer3节点和ca3节点
function startPeerForOrg3(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer3.yaml -o org3 -M Org3MSP -p peer0.org3.example.com -c couchdb3 -P 7984 -l 9051 -e 9053
    sh network_setup.sh up -f docker-compose-peer3.yaml
    
    sh network_setup.sh createCATemplate -f docker-compose-ca-org3.yaml -o org3.example.com -P 9054
    sh network_setup.sh up -f docker-compose-ca-org3.yaml
}

## 启动peer4节点和ca4节点
function startPeerForOrg4(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer4.yaml -o org4 -M Org4MSP -p peer0.org4.example.com -c couchdb4 -P 8984 -l 10051 -e 10053
    sh network_setup.sh up -f docker-compose-peer4.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org4.yaml -o org4.example.com -P 10054
    sh network_setup.sh up -f docker-compose-ca-org4.yaml
}

## 启动peer5节点和ca5节点
function startPeerForOrg5(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer5.yaml -o org5 -M Org5MSP -p peer0.org5.example.com -c couchdb5 -P 9984 -l 11051 -e 11053
    sh network_setup.sh up -f docker-compose-peer5.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org5.yaml -o org5.example.com -P 11054
    sh network_setup.sh up -f docker-compose-ca-org5.yaml
}

## 启动peer6节点和ca6节点
function startPeerForOrg6(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer6.yaml -o org6 -M Org6MSP -p peer0.org6.example.com -c couchdb6 -P 10984 -l 12051 -e 12053
    sh network_setup.sh up -f docker-compose-peer6.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org6.yaml -o org6.example.com -P 12054
    sh network_setup.sh up -f docker-compose-ca-org6.yaml
}

## 启动peer7节点和ca7节点
function startPeerForOrg7(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer7.yaml -o org7 -M Org7MSP -p peer0.org7.example.com -c couchdb7 -P 11984 -l 13051 -e 13053
    sh network_setup.sh up -f docker-compose-peer7.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org7.yaml -o org7.example.com -P 13054
    sh network_setup.sh up -f docker-compose-ca-org7.yaml
}

## 启动peer8节点和ca8节点
function startPeerForOrg8(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer8.yaml -o org8 -M Org8MSP -p peer0.org8.example.com -c couchdb8 -P 12984 -l 14051 -e 14053
    sh network_setup.sh up -f docker-compose-peer8.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org8.yaml -o org8.example.com -P 14054
    sh network_setup.sh up -f docker-compose-ca-org8.yaml
}

## 启动peer9节点和ca9节点
function startPeerForOrg9(){
    sh network_setup.sh createPeerTemplate -f docker-compose-peer9.yaml -o org9 -M Org9MSP -p peer0.org9.example.com -c couchdb9 -P 13984 -l 15051 -e 15053
    sh network_setup.sh up -f docker-compose-peer9.yaml

    sh network_setup.sh createCATemplate -f docker-compose-ca-org9.yaml -o org9.example.com -P 15054
    sh network_setup.sh up -f docker-compose-ca-org9.yaml
}

## 启动服务器1上的服务
function startServer1(){
   startOrderer1
}

## 启动服务器2上的服务
function startServer2(){
   startOrderer2
   startPeerForOrg4
}

## 启动服务器3上的服务
function startServer3(){
   startPeerForOrg1
}

## 启动服务器4上的服务
function startServer4(){
   startPeerForOrg2
}

## 启动服务器5上的服务
function startServer5(){
   startPeerForOrg3
}

function init(){
startServer1
startServer2
startServer3
startServer4
startServer5
startPeerForOrg5
startPeerForOrg6
startPeerForOrg7
startPeerForOrg8
startPeerForOrg9
}

# Parse commandline args
if [ "$1" = "-m" ]; then # supports old usage, muscle memory is powerful!
  shift
fi
MODE=$1
shift

while getopts "h?p:M:c:P:l:e:f:o:" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
  p)
    PEER_NAME=$OPTARG
    ;;
  o)
    ORG_NAME=$OPTARG
    ;;
  M)
    MSP_ID=$OPTARG
    ;;
  c)
    COUCHDB_NAME=$OPTARG
    ;;
  P)
    COUCHDB_PORT=$OPTARG
    ;;
  l)
    PEER_LISTEN_PORT=$OPTARG
    ;;
  e)
    PEER_EVENT_PORT=$OPTARG
    ;;
  f)
    COMPOSE_FILE=$OPTARG
    ;;
  ?)
    printHelp
    ::
  esac
done

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  source generateArtifacts.sh
elif [ "${MODE}" == "restart" ]; then ## Restart the network
  networkDown
  networkUp
elif [ "${MODE}" == "createPeerTemplate" ]; then ##create peer yaml file
  createPeerTemplate
elif [ "${MODE}" == "createCATemplate" ]; then ##create peer yaml file
  createCATemplate
elif [ "${MODE}" == "startServer1" ];then ## start server 1
    dcrm
    startServer1
elif [ "${MODE}" == "startServer2" ];then ## start server 2
    dcrm
    startServer2
elif [ "${MODE}" == "startServer3" ];then ## start server 3
    dcrm
    startServer3
elif [ "${MODE}" == "startServer4" ];then ## start server 4
    dcrm
    startServer4
elif [ "${MODE}" == "startServer5" ];then ## start server 5
    dcrm
    startServer5
elif [ "${MODE}" == "startPeer5" ];then ## start server 5
    startPeerForOrg5
elif [ "${MODE}" == "startPeer6" ];then ## start server 5
    startPeerForOrg6
elif [ "${MODE}" == "updateNetworkConfiguration" ];then
    updateNetworkConfiguration
elif [ "${MODE}" == "init" ];then
    init
else
  printHelp
  exit 1
fi