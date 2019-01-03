## Fabric Node App For  trace

### Prerequisites and setup:

* [Docker](https://www.docker.com/products/overview) - 17.06.2-ce or greater is required
* [Docker Compose](https://docs.docker.com/compose/overview/) - 1.14.0 or greater
* [Git client](https://git-scm.com/downloads) - needed for clone commands
* **Node.js** v8.12.0 ( __Node v7+ is not supported__ )
* **Golang** v1.10.1 or higher
* **Setup Environment** ()

```
git clone https://github.com/rising-programmer/fabric-node-sdk
cd fabric-node-sdk
./artifacts/channel/bootstrap.sh -s 1.1.0 1.1.0 0.4.7
```

Once you have completed the above setup, you will have provisioned a local network with the following docker container configuration:

* 4 CAs
* A Kafka Orderer cluster
* 4 peers (1 peer per Org)

#### Artifacts
* Crypto material has been generated using the **cryptogen** tool from Hyperledger Fabric and mounted to all peers, the orderering node and CA containers. More details regarding the cryptogen tool are available [here](http://hyperledger-fabric.readthedocs.io/en/latest/build_network.html#crypto-generator).
* An Orderer genesis block (genesis.block) and channel configuration transaction (mychannel.tx) has been pre generated using the **configtxgen** tool from Hyperledger Fabric and placed within the artifacts folder. More details regarding the configtxgen tool are available [here](http://hyperledger-fabric.readthedocs.io/en/latest/build_network.html#configuration-transaction-generator).

### Set up network environment
```
cd fabric-node-sdk/artifacts/channel
sh network_setup.sh init
```

* This launches the required network on your machine

### Run Node App
```
cd fabric-node-sd
./runApp.sh
```
* Installs the fabric-client and fabric-ca-client node modules
* And, starts the node app on PORT 4000

### Run Base Apis
```
./testAPIs.sh
```
* This create a channel named mychannel
* Helps peers to join mychannel
* Installs chaincode on peers
* Instantiate the chaincode

### REST APIs

### Request for User Token
```
curl -s -X POST \
  http://127.0.0.1:4000/api/v1/token \
  -H "content-type: application/json" \
  -d '{
        "username":"Jim",
     }'
```
- username : user's name

##### Response:
```
{
    "code": 200,
    "message": "Jim enrolled Successfully",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1MzY4MzY5NTgsInVzZXJuYW1lIjoiSmltIiwib3JnTmFtZSI6Ik9yZzEiLCJpYXQiOjE1MzY4MDA5NTh9.xPSP20obwgaKrrDxbwNeZtmOn6ngByWXcdN_TlEhK_E"
}
```
- code : 200 means success, other representatives fail 
- message : more detailed message for response
- token   : json web token



### Network configuration considerations

You have the ability to change configuration parameters by editing the network-config.yaml file.


#### Discover IP Address

To retrieve the IP Address for one of your network entities, issue the following command:

```
# this will return the IP Address for peer0
docker inspect peer0 | grep IPAddress
```

### Troubleshooting
Please visit the [TROUBLESHOOT.md](http://116.236.220.221:3001/randy2018/trace_kingland/src/release1.1/TROUBLESHOOT.md)TROUBLESHOOT.md to view the Troubleshooting TechNotes.

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.
