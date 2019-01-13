package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// Get returns the value of the specified asset key
func (t *SimpleChainCode) get(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect arguments. Expecting one")
	}

	value, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error("Failed to get key : "+ args[0])
	}
	if value == nil {
		return shim.Error(args[0] +" not found")
	}
	return shim.Success(value)
}