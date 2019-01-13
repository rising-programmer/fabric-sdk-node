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

docker rm -f $(docker ps -aq)
#dkrm

rm -rf ./mount/*

rm -rf ./fabric-client-kv-org*
