package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	"encoding/json"
	"fmt"
)

// == 数据上链接口 ==

func (t *SimpleChainCode) save(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	//参数校验，前三位参数是必须提供的
	if len(args[0]) <= 0 {
		return shim.Error("1st argument must be a non-empty string")
	}
	if len(args[1]) <= 0 {
		return shim.Error("2nd argument must be a non-empty string")
	}
	if len(args[2]) <= 0 {
		return shim.Error("3rd argument must be a non-empty string")
	}

	var className string = args[0] 			//类名
	var id string = args[1]       			//主键
	var jsonStr string = args[2] 		  	//JSON数据结构(string类型)
	var parentClassName string = args[3] 	//上轮节点类名
	var parentChaincodeName string = args[4]//父智能合约名称
	bytes := []byte(jsonStr)	  		    //将JSONString转换为bytes
	var err error

	//判断是否需要做上链前校验
	if parentClassName != ""{
		//解析上链数据
		var json2Map map[string]interface{}

		err = json.Unmarshal(bytes,&json2Map)
		if err != nil{
			return shim.Error("jsonStr unMarshal failed . source = "+string(bytes))
		}
		data,ok := json2Map["data"].(map[string]interface{})
		if !ok {
			return shim.Error("argument data is missing")
		}
		//拿到parentId
		parentId,ok := data["parentId"].(string)
		if !ok {
			return shim.Error("property parentId is missing")
		}
		//判断是否需要跨智能合约查询
		var response pb.Response
		if parentChaincodeName != ""{
			response = stub.InvokeChaincode(parentChaincodeName,[][]byte{[]byte("get"),[]byte(parentClassName+parentId)},"mychannel")
		}else{
			param :=[]string{parentClassName+parentId}
			response = t.get(stub,param)
		}
		//判断校验是否成交
		fmt.Printf("Invoke chaincode successful. Got response %s\n", response)
		if response.Status != 200 {
			return shim.Error("className : " + parentClassName + ", Id :" + parentId +" Not found")
		}
	}

	compositeKey := className + id //由类名+主键组成新的组合键

	err = stub.PutState(compositeKey, bytes) //数据上链
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}
