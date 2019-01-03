#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# verify the result of the end-to-end test
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
		echo
   		exit 1
	fi
}

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
        export CORE_PEER_LOCALMSPID="OrdererMSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
        export CORE_PEER_MSPCONFIGPATH=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp
        export ORDERER_CA=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
}

setGlobals () {
	PEER=$1
	ORG=$2
	FLAG=$3
	echo "FLAG========================>${FLAG}"
	echo "ORG=========================>${ORG}"
	if [ $ORG -eq 1 ] ; then
		export CORE_PEER_LOCALMSPID="Org1MSP"
		export CORE_PEER_TLS_ROOTCERT_FILE=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
		export CORE_PEER_MSPCONFIGPATH=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
		if [ $PEER -eq 0 ]; then
			export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
		else
			export CORE_PEER_ADDRESS=peer1.org1.example.com:8051
		fi
	elif [ $ORG -eq 2 ] ; then
		export CORE_PEER_LOCALMSPID="Org2MSP"
		export CORE_PEER_TLS_ROOTCERT_FILE=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
		export CORE_PEER_MSPCONFIGPATH=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
		if [ $PEER -eq 0 ]; then
			export CORE_PEER_ADDRESS=peer0.org2.example.com:8051
		else
			export CORE_PEER_ADDRESS=peer1.org2.example.com:10051
		fi

	elif [ $ORG -eq 3 ] ; then
		export CORE_PEER_LOCALMSPID="Org3MSP"
		export CORE_PEER_TLS_ROOTCERT_FILE=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
		export CORE_PEER_MSPCONFIGPATH=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
		if [ $PEER -eq 0 ]; then
			export CORE_PEER_ADDRESS=peer0.org3.example.com:9051
		else
			export CORE_PEER_ADDRESS=peer1.org3.example.com:12051
		fi

	elif [ $ORG -eq 4 ] ; then
		export CORE_PEER_LOCALMSPID="Org4MSP"
		export CORE_PEER_TLS_ROOTCERT_FILE=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
		export CORE_PEER_MSPCONFIGPATH=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
		if [ $PEER -eq 0 ]; then
			export CORE_PEER_ADDRESS=peer0.org4.example.com:10051
		else
			export CORE_PEER_ADDRESS=peer1.org4.example.com:12051
		fi
    #create peer env according to org
	elif [ $FLAG -eq 1 ]; then
	    export CORE_PEER_LOCALMSPID="Org${ORG}MSP"
		export CORE_PEER_TLS_ROOTCERT_FILE=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org${ORG}.example.com/peers/peer0.org${ORG}.example.com/tls/ca.crt
		export CORE_PEER_MSPCONFIGPATH=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/peerOrganizations/org${ORG}.example.com/users/Admin@org${ORG}.example.com/msp
		if [ $PEER -eq 0 ]; then
			export CORE_PEER_ADDRESS=peer0.org${ORG}.example.com:$[ORG -1 + 7]051
		fi
	else
		echo "================== ERROR !!! ORG Unknown =================="
	fi

	env |grep CORE
}


updateAnchorPeers() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG 1

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
		res=$?
                set +x
  else
                set -x
		peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
                set +x
  fi
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
	sleep $DELAY
	echo
}

## Sometimes Join takes time hence RETRY at least for 5 times
joinChannelWithRetry () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG 1

        set -x
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
        set +x
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
		sleep $DELAY
		joinChannelWithRetry $PEER $ORG
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to Join the Channel"
}

installChaincode () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG 1
	VERSION=${3:-1.0}
        set -x
	peer chaincode install -n example -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} >&log.txt
	res=$?
        set +x
	cat log.txt
	verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has Failed"
	echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
	echo
}

instantiateChaincode () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG 1
	VERSION=${3:-1.0}

	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer chaincode instantiate -o orderer1.example.com:7050 -C $CHANNEL_NAME -n example -l ${LANGUAGE} -v ${VERSION} -c '{"Args":[]}' -P "OR	('Org1MSP.peer','Org2MSP.peer')" >&log.txt
		res=$?
                set +x
	else
                set -x
		peer chaincode instantiate -o orderer1.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n example -l ${LANGUAGE} -v ${VERSION} -c '{"Args":[}' -P "OR	('Org1MSP.peer','Org2MSP.peer')" >&log.txt
		res=$?
                set +x
	fi
	cat log.txt
	verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

upgradeChaincode () {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG 1
	VERSION=${3:-1.0}
    endorser=""
    endorser="${endorser}OR ("
    for ((i=1; i<=$[ORG_NAME_NUMBER]; i++))
    do
        if [ $[ORG_NAME_NUMBER] == ${i} ];then
           endorser="${endorser}'Org${i}MSP.peer')"
        else
           endorser="${endorser}'Org${i}MSP.peer',"
        fi
    done
    set -x
    peer chaincode upgrade -o orderer1.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n example -v ${VERSION} -c '{"Args":["init"]}' -P "${endorser}"
    res=$?
	set +x
    cat log.txt
    verifyResult $res "Chaincode upgrade on org${ORG} peer${PEER} has Failed"
    echo "===================== Chaincode is upgraded on org${ORG} peer${PEER} ===================== "
    echo
}

chaincodeQuery () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG 1
  EXPECTED_RESULT=$3
  echo "===================== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
     set -x
     peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
	 res=$?
     set +x
     test $res -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

# fetchChannelConfig <channel_id> <output_json>
# Writes the current channel config for a given channel to a JSON file
fetchChannelConfig() {
  CHANNEL=$1
  OUTPUT=$2

  setOrdererGlobals

  echo "Fetching the most recent configuration block for the channel"
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel fetch config config_block.pb -o orderer1.example.com:7050 -c $CHANNEL --cafile $ORDERER_CA
    set +x
  else
    set -x
    peer channel fetch config config_block.pb -o orderer1.example.com:7050 -c $CHANNEL --tls --cafile $ORDERER_CA
    set +x
  fi

  echo "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
#  configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > "${OUTPUT}"

  configtxlator proto_decode --input config_block.pb --type common.Block --output tmp.json
  cat tmp.json | jq .data.data[0].payload.data.config > ${OUTPUT}
  set +x
}

# signConfigtxAsPeerOrg <org> <configtx.pb>
# Set the peerOrg admin of an org and signing the config update
signConfigtxAsPeerOrg() {
        PEERORG=$1
        TX=$2
        setGlobals 0 $PEERORG 1
        set -x
        peer channel signconfigtx -f "${TX}"
        set +x
}

# createConfigUpdate <channel_id> <original_config.json> <modified_config.json> <output.pb>
# Takes an original and modified config, and produces the config update tx which transitions between the two
createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config --output original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config --output modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb --output config_update.pb
  configtxlator proto_decode --input config_update.pb  --type common.ConfigUpdate --output config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
  set +x
}

chaincodeInvoke () {
	PEER=$1
	ORG=$2
	ORDERER_NAME=$3
export ORDERER_CA=/opt/kingland/trace_kingland/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer${ORDERER_NAME}.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo ${ORDERER_CA}
	setGlobals $PEER $ORG 1
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
#		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
		peer chaincode invoke -o orderer1.example.com:7050 -C $CHANNEL_NAME -n mycc -c '{"Args":["save","id":"5","objectType":"business",
	        "timestamp":"1544161048",
	        "hash":"b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9",
	        "blockId":"5",
	        "deviceId":"5"]}' >&log.txt
		res=$?
                set +x
	else
                set -x
		peer chaincode invoke -o orderer${ORDERER_NAME}.example.com:$[ORDERER_NAME+6]050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n example -c '{"Args":["save","business","5","1544161048","b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde8","3694b6d81f6ffa9ce0656deb9a5a5644dfa7e4a15f7fa59af4e7d8d90e911785","5","5","randy","org1"]}' >&log.txt
		res=$?
                set +x
	fi
	cat log.txt
	verifyResult $res "Invoke failed ${res}" >> error.log
	echo "===================== Invoke transaction on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== " >> succ.log
	echo
}

## create peer template
function createPeerTemplate1(){

#COMPOSE_FILE="$1"
#ORG_NAME="$2"
#MSP_ID="$3"
#PEER_NAME="$4"
#COUCHDB_NAME="$5"
#COUCHDB_PORT="$6"
#PEER_LISTEN_PORT="$7"
#PEER_EVENT_PORT="$8"

COMPOSE_FILE="docker-compose-peer-${ORG_NAME}.yaml"
MSP_ID="${ORG_NAME}MSP"
PEER_NAME="peer0.${ORG_NAME_LOWERCASE}.example.com"
COUCHDB_NAME="couchdb$[ORG_NAME_NUMBER * 2 -1]"
COUCHDB_PORT="$[ORG_NAME_NUMBER*2 -1 +5]984"
PEER_LISTEN_PORT="$[ORG_NAME_NUMBER * 2 -1 + 7]051"
PEER_EVENT_PORT="$[ORG_NAME_NUMBER * 2 -1 + 7]053"
#涉及到变量重写，所以放在最后
ORG_NAME="${ORG_NAME_LOWERCASE}"

    if [ -z ${COMPOSE_FILE} ] || [ -z ${ORG_NAME} ] || [ -z ${MSP_ID} ] || [ -z ${PEER_NAME} ] || [ -z ${COUCHDB_NAME} ] || [ -z ${COUCHDB_PORT} ] || [ -z ${PEER_LISTEN_PORT} ]|| [ -z ${PEER_EVENT_PORT} ]; then
     printHelp
    else
        ARCH=`uname -s | grep Darwin`
        if [ "$ARCH" == "Darwin" ]; then
            OPTS="-it"
        else
            OPTS="-i"
        fi

        cp docker-compose-peer-template.yaml ${COMPOSE_FILE}

        CURRENT_DIR=$PWD

        cd ${CURRENT_DIR}
        sed ${OPTS} "s/PEER_NAME/${PEER_NAME}/g" ${COMPOSE_FILE}
        sed ${OPTS} "s/COUCHDB_NAME/${COUCHDB_NAME}/g" ${COMPOSE_FILE}
        sed ${OPTS} "s/COUCHDB_PORT/${COUCHDB_PORT}/g" ${COMPOSE_FILE}
        sed ${OPTS} "s/MSP_ID/${MSP_ID}/g" ${COMPOSE_FILE}
        sed ${OPTS} "s/PEER_LISTEN_PORT/${PEER_LISTEN_PORT}/g" ${COMPOSE_FILE}
        sed ${OPTS} "s/PEER_EVENT_PORT/${PEER_EVENT_PORT}/g" ${COMPOSE_FILE}
        sed ${OPTS} "s/ORG_NAME/${ORG_NAME}/g" ${COMPOSE_FILE}
        fi

        cd -
}
