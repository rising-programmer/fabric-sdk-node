/*
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
*/

package main

import (
	"bytes"
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

//Chaincode implementation
type SimpleChaincode struct {
}

// Data model
type DataModel struct {
	ObjectType string `json:"objectType"` //objectType is used to distinguish the various types of objects in state database
	ID string `json:"id"`
	Timestamp string `json:"timestamp"`
	TransactionID string `json:"transactionId"`
	Hash string `json:"hash"`
	BlockID string `json:"blockId"`
	DeviceID string `json:"deviceId"`
	UserName string `json:"userName"`
	OrgName	string `json:"orgName"`
}

// ===================================================================================
// Main
// ===================================================================================
func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}

// Init initializes chaincode
// ===========================
func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

// Invoke - Our entry point for Invocations
// ========================================
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	fmt.Printf("function: %s,args: %s\n", function, args)

	// Handle different functions
	if function == "save" { //create a new marble
		return t.save(stub, args)
	} else if function == "query" { //find Data based on an ad hoc rich query
		return t.query(stub, args)
	}

	fmt.Println("invoke did not find func: " + function) //error
	return shim.Error("Received unknown function invocation")
}

// ============================================================
// - create a new data, store into chaincode state
// ============================================================
func (t *SimpleChaincode) save(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// ==== Input sanitation ====
	fmt.Println("- start init dataModel")
	//if len(args[0]) <= 0 {
	//	return shim.Error("1st argument must be a non-empty string")
	//}
	//if len(args[1]) <= 0 {
	//	return shim.Error("2nd argument must be a non-empty string")
	//}
	//if len(args[2]) <= 0 {
	//	return shim.Error("3rd argument must be a non-empty string")
	//}
	//if len(args[3]) <= 0 {
	//	return shim.Error("4th argument must be a non-empty string")
	//}
	//if len(args[4]) <= 0 {
	//	return shim.Error("5th argument must be a non-empty string")
	//}
	for i := 0; i < len(args)/9; i++ {
		var err error

		fmt.Printf("%s\n", args[i])
		objectType := args[1 + 9*i]
		id := args[2 + 9 * i]
		timestamp := args[3 + 9 * i]
		transactionID := args[4 + 9 * i]
		hash := args[5 + 9 * i]
		blockId := args[6 + 9 * i]
		deviceId := args[7 + 9 * i]
		userName := args[8 + 9 * i]
		orgName := args[9 + 9 * i]

		compositeKey := objectType + id

		// ==== Create data object and marshal to JSON ====
		businessModel := &DataModel{objectType, id, timestamp, transactionID,hash,blockId,deviceId,userName,orgName}
		businessJSONasBytes, err := json.Marshal(businessModel)
		if err != nil {
			return shim.Error(err.Error())
		}

		// === Save dataa to state ===
		err = stub.PutState(compositeKey, businessJSONasBytes)
		if err != nil {
			return shim.Error(err.Error())
		}
	}



	//err = stub.PutState("business6", businessJSONasBytes)
	//if err != nil {
	//	return shim.Error(err.Error())
	//}
	//err = stub.PutState("business7", businessJSONasBytes)
	//if err != nil {
	//	return shim.Error(err.Error())
	//}
	//err = stub.PutState("business8", businessJSONasBytes)
	//if err != nil {
	//	return shim.Error(err.Error())
	//}
	//err = stub.PutState("business9", businessJSONasBytes)
	//if err != nil {
	//	return shim.Error(err.Error())
	//}

	//  ==== Index the data to enable complex range queries, e.g. return all business type data ====
	//  An 'index' is a normal key/value entry in state.
	//  The key is a composite key, with the elements that you want to range query on listed first.
	//  In our case, the composite key is based on indexName~objectType~id~timestamp.
	//  This will enable very efficient state range queries based on composite keys matching indexName~color~*
	//indexName := "objectType~id~timestamp"
	//colorNameIndexKey, err := stub.CreateCompositeKey(indexName, []string{businessModel.ObjectType,businessModel.ID,businessModel.Timestamp})
	//if err != nil {
	//	return shim.Error(err.Error())
	//}
	////  Save index entry to state. Only the key name is needed, no need to store a duplicate copy of the data.
	////  Note - passing a 'nil' value will effectively delete the key from state, therefore we pass null character as value
	//value := []byte{0x00}
	//stub.PutState(colorNameIndexKey, value)

	// ==== data saved and indexed. Return success ====
	fmt.Println("- end save data")
	return shim.Success(nil)
}

// ===== Add hoc rich query ========================================================
// query method uses a query string to perform a query for data.
// Query string matching state database syntax is passed in and executed as is.
// Supports ad hoc queries that can be defined at runtime by the client.
// Only available on state databases that support rich query (e.g. CouchDB)
// =========================================================================================
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	//   0
	// "queryString"
	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	queryString := args[0]

	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

// =========================================================================================
// getQueryResultForQueryString executes the passed in query string.
// Result set is built and returned as a byte array containing the JSON results.
// =========================================================================================
func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {

	fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing QueryRecords
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

	return buffer.Bytes(), nil
}

