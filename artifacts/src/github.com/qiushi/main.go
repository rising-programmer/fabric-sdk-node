package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"

	"github.com/go-ini/ini"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	common "github.com/heixiongTT/qiushi-cc/common"
	digestsutils "github.com/heixiongTT/qiushi-cc/digestsutils"
	rsautils "github.com/heixiongTT/qiushi-cc/rsautils"
	"github.com/tidwall/gjson"
)

// Chaincode comment
type Chaincode struct {
}

var confs = make(map[string]string, 128)
var strategyConfs = make(map[string]string, 128)

//Init {"Args":["init"]}
func (t *Chaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fucName, args := stub.GetFunctionAndParameters()
	fmt.Printf("fucName is %s\narguments is %v\n", fucName, args)
	log.Printf("fucName is %s\narguments is %v\n", fucName, args)
	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting great than 1")
	}
	workMode := args[0]
	if workMode == "direct" {
		confs["pubKey"] = args[1]
		confs["privKey"] = args[2]
		confs["partner"] = args[3]
		strategyConfs["cryptoMethod"] = "RSA"
		strategyConfs["digestsMethod"] = "MD5"
		strategyConfs["signatureMethod"] = "RSA"
		fmt.Printf("pubKey is %s\n", args[1])
		fmt.Printf("privKey is %s\n", args[2])
		fmt.Printf("partner is %s\n", args[3])
		return shim.Success([]byte(nil))
	}
	if workMode == "config" {
		configPath := args[1]
		log.Printf("config file path is:%s\n", configPath)
		fmt.Printf("config file path is:%s\n", configPath)
		cfg, err := ini.Load(configPath)

		if err != nil {
			log.Fatal(err)
		}

		pubPath := cfg.Section("Security").Key("public_key_path").String()
		privPath := cfg.Section("Security").Key("private_key_path").String()
		passwd := cfg.Section("Security").Key("ks_pwd").String()
		cryptoMethod := cfg.Section("Security").Key("crypto_method").String()
		digestsMethod := cfg.Section("Security").Key("digests_method").String()
		signatureMethod := cfg.Section("Security").Key("signature_method").String()
		partner := cfg.Section("Merchant").Key("partner").String()

		pubKey, err := rsautils.DumpPublicKeyBase64(pubPath)
		if err != nil {
			errMsg := fmt.Sprintf("dump public key from [%s] meet error", pubPath)
			return shim.Error(errMsg)
		}
		privKey, err := rsautils.DumpKSBase64(privPath, passwd, partner)
		if err != nil {
			errMsg := fmt.Sprintf("dump private key from [%s] meet error", privPath)
			return shim.Error(errMsg)
		}

		confs["pubKey"] = pubKey
		confs["privKey"] = privKey
		confs["partner"] = partner
		strategyConfs["cryptoMethod"] = cryptoMethod
		strategyConfs["digestsMethod"] = digestsMethod
		strategyConfs["signatureMethod"] = signatureMethod
		fmt.Printf("pubKey is %s\n", pubKey)
		fmt.Printf("partner is %s\n", partner)
		fmt.Printf("cryptoMethod is %s\n", cryptoMethod)
		fmt.Printf("digestsMethod is %s\n", digestsMethod)
		fmt.Printf("signatureMethod is %s\n", signatureMethod)
		return shim.Success([]byte(configPath))
	}
	return shim.Success([]byte(nil))
}

//{"Args":["query","key"]}'
func (t *Chaincode) query(stub shim.ChaincodeStubInterface, key string) pb.Response {
	fmt.Printf("query %s\n", key)
	bytes, err := stub.GetState(key)
	if err != nil {
		return shim.Error("query fail " + err.Error())
	}
	if bytes == nil {
		return shim.Success([]byte(nil))
	}
	decryptString, err := parseMultiSegData(string(bytes))
	if err != nil {
		return shim.Error("parseMultiSegData error " + err.Error())
	}
	return shim.Success([]byte(decryptString))
}

func (t *Chaincode) exists(stub shim.ChaincodeStubInterface, key string) pb.Response {
	fmt.Printf("exists %s\n", key)
	bytes, err := stub.GetState(key)
	if err != nil {
		return shim.Error("query fail " + err.Error())
	}
	if bytes != nil {
		return shim.Success([]byte("exists"))
	}
	return shim.Success([]byte("not_exists"))
}

//{"Args":["write","key","value"]}'
func (t *Chaincode) write(stub shim.ChaincodeStubInterface, key, value string) pb.Response {
	fmt.Printf("write %s, value is %s\n", key, value)
	if err := stub.PutState(key, []byte(value)); err != nil {
		return shim.Error("write fail " + err.Error())
	}
	return shim.Success(nil)
}

//{"Args":["translateData","ID","PID",Licensee]}
func (t *Chaincode) translateData(stub shim.ChaincodeStubInterface, id, pid, licensee, metaInfo string) pb.Response {
	fmt.Printf("id %s,pid is %s,licensee is %s\n", id, pid, licensee)
	gbytes, gerr := stub.GetState(pid)
	if gerr != nil {
		return shim.Error("query fail " + gerr.Error())
	}
	encryptJSONValue := string(gbytes)
	fmt.Printf("encryptJSONValue is %s\n", encryptJSONValue)
	cryptoDescriptor := gjson.Get(encryptJSONValue, "header.cryptoDescriptor").String()
	fmt.Printf("header.cryptoDescriptor is %s\n", cryptoDescriptor)
	var cds []common.CryptoDescriptor
	if err := json.Unmarshal([]byte(cryptoDescriptor), &cds); err != nil {
		return shim.Error("unmarshal cryptoDescriptor error:" + err.Error())
	}
	decryptDataMap, err := common.DecryptoDataByDescriptor(encryptJSONValue, cds, confs["privKey"])
	strategyBytes, err := json.Marshal(strategyConfs)
	if err != nil {
		return shim.Error("marshall strategyConfs error: " + err.Error())
	}
	header := common.Header{
		Key:              id,
		PKey:             pid,
		Licensee:         licensee,
		Authorizer:       confs["pubKey"],
		Strategy:         string(strategyBytes),
		Partner:          confs["partner"],
		CryptoDescriptor: cryptoDescriptor,
	}

	if metaInfo != "" {
		header.MetaInfo = metaInfo
	}

	if err != nil {
		fmt.Println(err)
	}
	decryptDataBytes, err := json.Marshal(decryptDataMap)
	if err != nil {
		fmt.Println(err)
	}
	value := string(decryptDataBytes)
	digests := gjson.Get(encryptJSONValue, "footer.digests").String()
	signature := rsautils.RSASignature(confs["privKey"], digests)

	footer := common.Footer{
		Digests:   digests,
		Signature: signature,
	}

	var writeTo = make(map[string]interface{}, 128)

	rawDataMap, err := common.CryptoDataByDescriptor(value, cds, licensee)
	if err != nil {
		return shim.Error("@@CryptoDataByDescriptor meet error: " + err.Error())
	}
	for key, value := range rawDataMap {
		writeTo[key] = value
	}
	writeTo["header"] = header
	writeTo["footer"] = footer
	bytes, err := json.Marshal(writeTo)
	if err != nil {
		return shim.Error("json marshal error: " + err.Error())
	}
	if err := stub.PutState(id, bytes); err != nil {
		return shim.Error("write fail " + err.Error())
	}

	var ret = make(map[string]interface{}, 4)

	txID := stub.GetTxID()

	ret["transactionId"] = txID

	bytes2, err2 := json.Marshal(ret)
	if err2 != nil {
		return shim.Error("json marshal error: " + err2.Error())
	}
	return shim.Success(bytes2)
}

//{"Args":["writeMultiSegData","key","value",cryptoDescriptor]}
func (t *Chaincode) writeMultiSegData(stub shim.ChaincodeStubInterface, key, value, cryptoDescriptor, metaInfo string) pb.Response {
	fmt.Printf("write %s,value is %s,SegDescriptor is %s\n", key, value, cryptoDescriptor)

	var cds []common.CryptoDescriptor
	if err := json.Unmarshal([]byte(cryptoDescriptor), &cds); err != nil {
		return shim.Error("unmarshal cryptoDescriptor error: " + err.Error())
	}
	strategyBytes, err := json.Marshal(strategyConfs)
	if err != nil {
		return shim.Error("marshall strategyConfs error: " + err.Error())
	}

	header := common.Header{
		Key:              key,
		PKey:             key,
		Licensee:         confs["pubKey"],
		Authorizer:       confs["pubKey"],
		Strategy:         string(strategyBytes),
		Partner:          confs["partner"],
		CryptoDescriptor: cryptoDescriptor,
	}

	if metaInfo != "" {
		header.MetaInfo = metaInfo
	}

	digests := digestsutils.MD5(value)
	signature := rsautils.RSASignature(confs["privKey"], digests)

	footer := common.Footer{
		Digests:   digests,
		Signature: signature,
	}

	var writeTo = make(map[string]interface{}, 128)
	writeTo["header"] = header
	writeTo["footer"] = footer
	rawDataMap, err := common.CryptoDataByDescriptor(value, cds, confs["pubKey"])
	if err != nil {
		return shim.Error("@@CryptoDataByDescriptor meet error: " + err.Error())
	}
	for key, value := range rawDataMap {
		writeTo[key] = value
	}
	bytes, err := json.Marshal(writeTo)
	if err != nil {
		return shim.Error("json marshal error: " + err.Error())
	}
	if err := stub.PutState(key, bytes); err != nil {
		return shim.Error("write fail " + err.Error())
	}

	var ret = make(map[string]interface{}, 4)

	txID := stub.GetTxID()

	ret["transactionId"] = txID

	bytes2, err2 := json.Marshal(ret)
	if err2 != nil {
		return shim.Error("json marshal error: " + err2.Error())
	}
	return shim.Success(bytes2)
}

func parseMultiSegData(encryptJSONValue string) (string, error) {
	cryptoDescriptor := gjson.Get(encryptJSONValue, "header.cryptoDescriptor").String()
	var cds []common.CryptoDescriptor
	if err := json.Unmarshal([]byte(cryptoDescriptor), &cds); err != nil {
		return encryptJSONValue, fmt.Errorf("unmarshal cryptoDescriptor error: " + err.Error())
	}
	decryptDataMap, err := common.DecryptoDataByDescriptor(encryptJSONValue, cds, confs["privKey"])
	if err != nil {
		fmt.Println(err)
	}

	decryptBytes, err := json.Marshal(decryptDataMap)
	if err != nil {
		fmt.Println(err)
	}
	decryptData := string(decryptBytes)
	return decryptData, nil
}

func (t *Chaincode) queryByParam(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	queryString := args[0]

	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		fmt.Printf("@@queryByParam mett error [%s]\n.", err.Error())
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

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
		var decryptBuffer bytes.Buffer
		decryptBuffer.WriteString("{\"Key\":")
		decryptBuffer.WriteString("\"")
		decryptBuffer.WriteString(queryResponse.Key)
		//fmt.Printf("queryResponse.Key is[%s]\n", queryResponse.Key)
		decryptBuffer.WriteString("\"")

		decryptBuffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		//fmt.Printf("queryResponse.Value is[%s]\n", queryResponse.Value)
		decryptString, err := parseMultiSegData(string(queryResponse.Value))
		if err != nil {
			fmt.Printf("parseMultiSegData meet error [%s]\n", err.Error())
			decryptBuffer.WriteString(string(queryResponse.Value))
		} else {
			decryptBuffer.WriteString(decryptString)
		}
		decryptBuffer.WriteString("}")
		buffer.WriteString(decryptBuffer.String())
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

	return buffer.Bytes(), nil
}

func (t *Chaincode) delByKey(stub shim.ChaincodeStubInterface, key string) pb.Response {
	fmt.Printf("del %s\n", key)
	err := stub.DelState(key)
	if err != nil {
		return shim.Error("delete fail :" + err.Error())
	}
	return shim.Success([]byte("SUCCESS"))
}

//Invoke export
func (t *Chaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	switch function {
	case "query":
		if len(args) != 1 {
			return shim.Error("parametes's number is wrong")
		}
		return t.query(stub, args[0])
	case "exists":
		if len(args) != 1 {
			return shim.Error("parametes's number is wrong")
		}
		return t.exists(stub, args[0])
	case "queryByParam":
		if len(args) != 1 {
			return shim.Error("parametes's number is wrong")
		}
		return t.queryByParam(stub, args)
	//"ID","value","EncryptDescriptor"
	case "encrypt":
		if len(args) == 3 {
			return t.writeMultiSegData(stub, args[0], args[1], args[2], "")
		}
		if len(args) == 4 {
			return t.writeMultiSegData(stub, args[0], args[1], args[2], args[3])
		}
		return shim.Error("parametes's number is wrong")
	//ID PID Licensee
	case "translate":

		if len(args) == 3 {
			return t.translateData(stub, args[0], args[1], args[2], "")
		}
		if len(args) == 4 {
			return t.translateData(stub, args[0], args[1], args[2], args[3])
		}
		return shim.Error("parametes's number is wrong")
	case "del": //删除
		if len(args) != 1 {
			return shim.Error("parametes's number is wrong")
		}
		return t.delByKey(stub, args[0])
	default:
		return shim.Error("Invalid invoke function name.")
	}
}

func main() {
	err := shim.Start(new(Chaincode))
	if err != nil {
		fmt.Printf("Error starting Chaincode chaincode: %s", err)
	}
}
