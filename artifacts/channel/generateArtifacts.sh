#!/usr/bin/env bash
CRYPTOGEN=$PWD/bin/cryptogen
CONFIGTXGEN=$PWD/bin/configtxgen
CHANNEL_NAME=$1
: ${CHANNEL_NAME:="mychannel"}
function buildCryptogenTools(){
	if [ -f "$CONFIGTXGEN" ]; then
	    echo
	else
	    echo "configtxgen not found"
	    exit 1
	fi
}

## Generates Org certs using cryptogen tool
function generateCerts (){
	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"
	if [ -d "crypto-config" ]; then
      rm -Rf crypto-config
    fi
	${CRYPTOGEN} generate --config=./crypto-config.yaml
	echo
}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {
	echo "##########################################################"
	echo "#########  Generating Orderer Genesis block ##############"
	echo "##########################################################"
	${CONFIGTXGEN} -profile TwoOrgsOrdererGenesis -outputBlock ./genesis.block

	echo
	echo "#################################################################"
	echo "### Generating channel configuration transaction 'channel.tx' ###"
	echo "#################################################################"
	${CONFIGTXGEN} -profile TwoOrgsChannel -outputCreateChannelTx ./mychannel.tx -channelID ${CHANNEL_NAME} 
}

buildCryptogenTools
generateCerts
generateChannelArtifacts