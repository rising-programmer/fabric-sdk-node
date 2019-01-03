docker rm -f $(docker ps -aq)

rm -rf ./mount/*

rm -rf ./fabric-client-kv-org*
