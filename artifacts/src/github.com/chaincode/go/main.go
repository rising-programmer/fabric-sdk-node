package main

import (
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type SimpleChainCode struct {
}
// == 智能合约初始化方法 ==
func (t *SimpleChainCode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

// == 智能合约执行入口 ==
func (t *SimpleChainCode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters() //获取方法和参数
	fmt.Printf("function: %s,args: %s\n", function, args)
	//路由
	if function == "save" {//数据上链
		return t.save(stub,args)
	} else if function == "query" {//普通查询(溯源)
		return t.query(stub, args)
	} else if function == "queryWithPagination" {//分页查询
		return t.queryWithPagination(stub,args)
	} else if function == "queryTotalCount" {//查询总条目(分页)
		return t.queryTotalCount(stub,args)
	} else if function == "get"{//键值对查询
		return t.get(stub,args)
	}
	return shim.Error("Invalid invoke function name. Expecting \"save\" \"query\" \"queryWithPagination\" \"queryTotalCount\" \"get\" ")
}

func main() {
	err := shim.Start(new(SimpleChainCode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}
