#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

function dkcl(){
        CONTAINER_IDS=$(docker ps -aq)
	echo
        if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
                echo "========== No containers available for deletion =========="
        else
                docker rm -f $CONTAINER_IDS
        fi
	echo
}

function dkrm(){
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
	echo
        if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
		echo "========== No images available for deletion ==========="
        else
           docker rmi -f ${DOCKER_IMAGE_IDS}
        fi
	echo
}

function rmCache(){
    rm -rf ./fabric-client-kv-org*
    rm -rf /tmp/fabric-client-kv-org*
    rm -rf mount/*
}

function restartNetwork() {
	echo

  #teardown the network and clean the containers and intermediate images
	docker-compose -f ./artifacts/docker-compose.yaml down
	dkcl
	dkrm

	#Cleanup the stores
	rm -rf ./fabric-client-kv-org*

	#Start the network
	docker-compose -f ./artifacts/docker-compose.yaml up -d
	echo
}

function installNodeModules() {
	echo
	if [ -d node_modules ]; then
		echo "============== node modules installed already ============="
	else
		echo "============== Installing node modules ============="
		npm install --registry=https://registry.npm.taobao.org
	fi
	echo
}

installNodeModules
#rmCache
export DIR=$PWD
cd ./artifacts/channel/
sh network_setup.sh updateNetworkConfiguration
#sh network_setup.sh init
cd ${DIR}

#杀掉node进程&启动node服务
ps -e|grep app.js|awk '{print $1}' | xargs -n1 kill -9
nohup node app.js  > app.log 2>&1 &
sleep 5
./init.sh