let reqUtils = require('./reqUtils');
let errors = require('./errors');
let invoke = require('./invoke-transaction');
let queryUtil = require('./query');
let helper = require('./helper');
let logger = helper.getLogger('sdkUtils');
let crypto = require('crypto');
let Enum = require('enum');
let config = require('../config.json');
let request = require('request');


let myEnum = new Enum({
    VALID: 0,
    NIL_ENVELOPE: 1,
    BAD_PAYLOAD: 2,
    BAD_COMMON_HEADER: 3,
    BAD_CREATOR_SIGNATURE: 4,
    INVALID_ENDORSER_TRANSACTION: 5,
    INVALID_CONFIG_TRANSACTION: 6,
    UNSUPPORTED_TX_PAYLOAD: 7,
    BAD_PROPOSAL_TXID: 8,
    DUPLICATE_TXID: 9,
    ENDORSEMENT_POLICY_FAILURE: 10,
    MVCC_READ_CONFLICT: 11,
    PHANTOM_READ_CONFLICT: 12,
    UNKNOWN_TX_TYPE: 13,
    TARGET_CHAIN_NOT_FOUND: 14,
    MARSHAL_TX_ERROR: 15,
    NIL_TXACTION: 16,
    EXPIRED_CHAINCODE: 17,
    CHAINCODE_VERSION_CONFLICT: 18,
    BAD_HEADER_EXTENSION: 19,
    BAD_CHANNEL_HEADER: 20,
    BAD_RESPONSE_PAYLOAD: 21,
    BAD_RWSET: 22,
    ILLEGAL_WRITESET: 23,
    INVALID_OTHER_REASON: 255
});

/**
 * 数据上链接口
 * @param req
 * @param res
 */
let save = function (req, res) {
    let data = req.body.data;
    //通道名称，默认mychannel
    let channelName = req.body.channelName || "mychannel";
    //智能合约名称，默认example
    let chaincodeName = req.body.chaincodeName || "example";
    //peer节点url
    let peersUrls = req.body.peersUrls;
    //智能合约方法名
    let functionName = req.body.functionName || "save";
    //用户
    let username = req.username;
    //组织
    let orgName = req.orgname;
    //数据检查
    if(reqUtils.isEmpty(data)){
        throw new errors.NotFound("Key data");
    }
    if(!(data instanceof Array)){
        throw new errors.SystemError("data must be an array");
    }
    for (let i = 0; i < data.length; i++) {
        let args = [];
        args[0] = data[i].objectType;
        args[1] = data[i].id;
        args[2] = data[i].timestamp;
        args[3] = data[i].hash;
        args[5] = data[i].blockId;
        args[6] = data[i].deviceId;
        if(args[0] !== "business" && args[0] !== "iot"){
            throw new errors.SystemError("objectType is not defined correctly，expect iot or business")
        }
        if(reqUtils.isEmpty(args[1])){
            throw new errors.SystemError("id argument must be a non-empty string");
        }
        if(reqUtils.isEmpty(args[2])){
            throw new errors.SystemError("timestamp argument must be a non-empty string");
        }
        if(reqUtils.isEmpty(args[3])){
            throw new errors.SystemError("hash argument must be a non-empty string");
        }
    }

    //返回值
    let promises = [];
    let ret = [];

    //数据上链

    let invokePromise = invoke.invokeChaincode(peersUrls, channelName, chaincodeName, functionName, data, username, orgName).then(message => {
        ret.push(message);
    });
    promises.push(invokePromise);
    // let args = [];
    // args[0] = data;
    // let invokePromise = invoke.invokeChaincode(peersUrls, channelName, chaincodeName, functionName, args, username, orgName).then(message => {
    //     ret.push(message);
    // });
    // promises.push(invokePromise);
    Promise.all(promises).then(message => {
        res.json(reqUtils.getResponse("操作成功",200,ret));
    }).catch(err => {
        res.json(reqUtils.getErrorMsg(err.message));
    });
};

/**
 * 数据查询
 * @param req
 * @param res
 * @return {Promise.<void>}
 */
let query = async function (req,res) {
    let peer = req.body.peer || "peer0.org1.example.com";
    let chaincodeName = req.body.chaincodeName || "example";
    let channelName = req.body.channelName || "mychannel";
    let fcn = "query";
    //数据类型
    let objectType = req.body.objectType;
    //查询起止时间
    let start = req.body.start;
    let end = req.body.end;
    //主键
    let id = req.body.id;
    //区块ID
    let blockId = req.body.blockId;
    //设备ID
    let deviceId = req.body.deviceId;
    //默认查询器
    let selector = {};
    //默认查询条件，过滤索引数据
    selector.timestamp = {"$gte": 1};
    //构造查询条件
    if(!reqUtils.isEmpty(objectType)){
        selector.objectType = objectType;
    }
    if(!reqUtils.isEmpty(start) && !reqUtils.isEmpty(end)){
        selector.timestamp = {"$gte": start,"$lte":end};
    }else if(!reqUtils.isEmpty(start)){
        selector.timestamp = {"$gte": start};
    }else if (!reqUtils.isEmpty(end)){
        selector.timestamp = {"$lte": end};
    }
    if(!reqUtils.isEmpty(id)){
        selector.id = id;
    }
    if(!reqUtils.isEmpty(blockId)){
        selector.blockId = blockId;
    }
    if(!reqUtils.isEmpty(deviceId)){
        selector.deviceId = deviceId;
    }
    let args = {};
    args.selector = selector;
    args.use_index = ["_design/indexTimestampDoc","indexTimestamp"];
    args.sort = [{"objectType":"asc"},{"timestamp": "asc"}];
    args.fields = ["objectType","hash","id","timestamp","blockId","deviceId","transactionId"];
    try {
        let datas = await queryUtil.queryChaincode(peer,channelName,chaincodeName,args,fcn,req.username,req.orgname);
        let ret = [];
        if(!reqUtils.isEmpty(datas)){
            datas = JSON.parse(datas);
            for(let i = 0; i < datas.length ; i++){
                ret.push(datas[i].Record);
            }
        }
        res.send(reqUtils.getResponse("操作成功",200,ret));
    }catch (error){
        res.send(reqUtils.getErrorMsg(error.message));
    }
};

/**
 * HASH校验
 * @param req
 * @param res
 * @return {Promise.<void>}
 */
let hashVerify = function (req,res) {
    let peer = req.body.peer || "peer0.org1.example.com";
    let chaincodeName = req.body.chaincodeName || "example";
    let channelName = req.body.channelName || "mychannel";
    let fcn = req.body.fcn || "query";
    //数据类型
    let objectType = req.body.objectType;
    //查询起止时间
    let start = req.body.start;
    let end = req.body.end;
    //数据hash
    let hash = req.body.hash;
    //区块ID
    let blockId = req.body.blockId;
    //设备ID
    let deviceId = req.body.deviceId;
    //参数校验
    if(reqUtils.isEmpty(objectType)){
        throw new errors.SystemError("objectType argument must be a non-empty string");
    }
    if(reqUtils.isEmpty(start)){
        throw new errors.SystemError("start argument must be a non-empty string");
    }
    if(reqUtils.isEmpty(end)){
        throw new errors.SystemError("end argument must be a non-empty string");
    }
    if(reqUtils.isEmpty(hash)){
        throw new errors.SystemError("hash argument must be a non-empty string");
    }
    //默认查询器
    let selector = {};
    //默认查询条件，过滤索引数据
    selector.timestamp = {"$gte": 1};
    //构造查询条件
    if(!reqUtils.isEmpty(objectType)){
        selector.objectType = objectType;
    }
    if(!reqUtils.isEmpty(start) && !reqUtils.isEmpty(end)){
        selector.timestamp = {"$gte": start,"$lte":end};
    }else if(!reqUtils.isEmpty(start)){
        selector.timestamp = {"$gte": start};
    }else if (!reqUtils.isEmpty(end)){
        selector.timestamp = {"$lte": end};
    }
    if(!reqUtils.isEmpty(blockId)){
        selector.blockId = blockId;
    }
    if(!reqUtils.isEmpty(deviceId)){
        selector.deviceId = deviceId;
    }
    let args = {};
    args.selector = selector;
    args.use_index = ["_design/indexTimestampDoc","indexTimestamp"];
    args.sort = [{"objectType":"asc"},{"timestamp": "asc"}];
    args.fields = ["objectType","hash","id","timestamp","blockId","deviceId","transactionId"];
    queryUtil.queryChaincode(peer,channelName,chaincodeName,args,fcn,req.username,req.orgname).then(datas=>{
        let ret = [];
        let target;
        if(!reqUtils.isEmpty(datas)){
            datas = JSON.parse(datas);
            let sha256 = crypto.createHash("sha256");
            for(let i = 0; i < datas.length ; i++){
                sha256.update(datas[i].Record["hash"]);
                ret.push(datas[i].Record);
            }
            target = sha256.digest("hex");
        }
        if(hash === target){
            res.send(reqUtils.getResponse("HASH校验成功",200,ret));
        }else{
            logger.error("original hash:%s,target hash:%s",hash,target);
            res.send(reqUtils.getErrorMsg("HASH校验失败"));
        }
    }).catch(error=>{
        res.send(reqUtils.getErrorMsg(error.message));
    });
};

/**
 * 根据transactionId查询
 * @param req
 * @param res
 */
let queryByTransactionId = function (req,res) {
    //transactionId
    let transactionId = req.body.transactionId;
    let peer = req.body.peer || "peer0.org1.example.com";
    let channelName = "mychannel";
    //参数校验
    if(reqUtils.isEmpty(transactionId)){
        throw new errors.SystemError("transactionId argument must be a non-empty string");
    }
    //根据txIx查询transaction
    queryUtil.getTransactionByID(peer, channelName, transactionId, req.username, req.orgname).then(message=>{
        if (message && message.transactionEnvelope) {
            //数据解析
            let entity = message.transactionEnvelope.payload.data.actions[0].payload.action.proposal_response_payload.extension.results.ns_rwset[0].rwset.writes[1].value;
            res.send(reqUtils.getResponse("查询成功",200,JSON.parse(entity)));
        } else {
            res.send(reqUtils.getErrorMsg("查询失败",404));
        }
    }).catch(error=>{
        logger.error("queryByTransactionId failed ! transactionId = %s,errorMsg=%s",transactionId,JSON.stringify(error));
        res.send(reqUtils.getErrorMsg("查询失败",500));
    });
};

/**
 * 格式化交易
 * @param txObj
 * @return {{txhash: *, validation_code: string, payload_proposal_hash: string, creator_msp_id: *, endorser_msp_id: Array, chaincodename: string, type: *, createdt: Date, read_set: *, write_set: *, channelname: *}}
 */
function formatTransaction (txObj){
    let txid = txObj.payload.header.channel_header.tx_id;
    let validation_code = '';
    let payload_proposal_hash = '';
    let chaincode = '';
    let rwset;
    let readSet;
    let writeSet;
    let mspId = [];
    let blockId;
    let deviceId;
    let timestamp;
    let channelName = txObj.payload.header.channel_header.channel_id;
    if (txid !== undefined && txid !== '') {
        validation_code = myEnum.get(
            parseInt(txObj.validationCode)
        ).key;
    }
    if (txObj.payload.data.actions !== undefined) {
        payload_proposal_hash =
            txObj.payload.data.actions[0].payload.action.proposal_response_payload
                .proposal_hash;

        chaincode =
            txObj.payload.data.actions[0].payload.action.proposal_response_payload
                .extension.chaincode_id.name;
        rwset =
            txObj.payload.data.actions[0].payload.action.proposal_response_payload
                .extension.results.ns_rwset;
        readSet = rwset.map(i => {
            return {
                chaincode: i.namespace,
                set: i.rwset.reads
            };
        });
        writeSet = rwset.map(i => {
            return {
                chaincode: i.namespace,
                set: i.rwset.writes
            };
        });
        try{
            data = JSON.parse(writeSet[0].set[1].value);
            blockId = data.blockId;
            deviceId = data.deviceId;
            timestamp = new Date(data.timestamp * 1000).toLocaleString();
        }catch (error){
            logger.error(error);
        }
        mspId = txObj.payload.data.actions[0].payload.action.endorsements.map(
            i => {
                return i.endorser.Mspid;
            }
        );
    }
    return  {
        txhash: txObj.payload.header.channel_header.tx_id,
        validation_code: validation_code,
        payload_proposal_hash: payload_proposal_hash,
        creator_msp_id: txObj.payload.header.signature_header.creator.Mspid,
        endorser_msp_id: mspId,
        chaincodename: chaincode,
        type: txObj.payload.header.channel_header.typeString,
        createdt: new Date(txObj.payload.header.channel_header.timestamp),
        read_set: readSet,
        write_set: writeSet,
        channelname: channelName,
        blockId:blockId,
        deviceId:deviceId,
        timestamp:timestamp
    };
}

/**
 * 数据分页查询
 * @param req
 * @param res
 * @return {Promise.<void>}
 */
let queryWithPagination = async function (req,res) {
    let peers = req.body.peers || "peer0.org1.example.com";
    let chaincodeName = req.params.chaincodeName || "example";
    let channelName = req.params.channelName || "mychannel";
    let fcn = req.body.fcn || "query";
    //区块ID
    let blockId = req.body.blockId;
    //设备ID
    let deviceId = req.body.deviceId;
    //页码
    let pageNo = req.body.pageNo || 1;
    //分页大小
    let pageSize = req.body.pageSize || 10;
    //数据长度
    let total;
    //交易IDs
    let transactionIds = req.body.transactionIds;
    //数据类型
    let objectType = req.body.objectType;
    //查询起止时间
    let start = req.body.start;
    let end = req.body.end;

    //默认查询器
    let selector = {};
    //默认查询条件，过滤索引数据
    selector.timestamp = {"$gte": 1};
    //构造查询条件
    if(!reqUtils.isEmpty(objectType)){
        selector.objectType = objectType;
    }
    if(!reqUtils.isEmpty(start) && !reqUtils.isEmpty(end)){
        selector.timestamp = {"$gte": start,"$lte":end};
    }else if(!reqUtils.isEmpty(start)){
        selector.timestamp = {"$gte": start};
    }else if (!reqUtils.isEmpty(end)){
        selector.timestamp = {"$lte": end};
    }
    if(!reqUtils.isEmpty(transactionIds)) {
        if(typeof transactionIds === "string"){
            transactionIds = JSON.parse(transactionIds);
        }
        if(transactionIds.length > 0){
            selector.transactionId = {"$in": transactionIds};
        }
    }
    if(!reqUtils.isEmpty(blockId)){
        selector.blockId = blockId;
    }
    if(!reqUtils.isEmpty(deviceId)){
        selector.deviceId = deviceId;
    }
    let args = {};
    args.selector = selector;
    args.use_index = ["_design/indexTimestampDoc","indexTimestamp"];
    args.sort = [{"objectType":"asc"},{"timestamp": "asc"}];
    args.fields = ["objectType","hash","id","timestamp","transactionId","blockId","deviceId"];
    try {
        let datas = await queryUtil.queryChaincode(peers,channelName,chaincodeName,args,fcn,req.username,req.orgname);
        let ret = [];
        if(!reqUtils.isEmpty(datas)){
            datas = JSON.parse(datas);
            total = datas.length;
            for(let i = 0; i < datas.length ; i++){
                ret.push(datas[i].Record["transactionId"]);
            }
            //数据截取(用于分页)
            ret = ret.slice((pageNo-1)*pageNo,pageNo * pageSize);
        }
        let response = await queryByTransactionIds(ret);
        if(!response || response.status !== 200){
            res.json(reqUtils.getErrorMsg("查询失败"));
            return;
        }
        let rows = response.rows;
        for(let i = 0; i< rows.length ; i ++){
            for(let j = 0 ; j < datas.length ; j ++){
                let data = datas[j].Record;
                if(rows[i].txhash === data.transactionId){
                    rows[i].blockId = data.blockId;
                    rows[i].deviceId = data.deviceId;
                    rows[i].timestamp = data.timestamp;
                }
            }
        }

        rows = rows.sort(compare("createdt")).reverse();
        res.json({
            "code":  200,
            "message": "查询成功",
            "data": rows,
            "total":total,
            "pageNo":pageNo,
            "pageSize":pageSize
        });
    }catch (error){
        res.send(reqUtils.getErrorMsg(error.message));
    }
};

/**
 * JSON数据属性排序比较器
 * @param property
 * @return {Function}
 */
function compare(property){
    return function(a,b){
        let value1 = a[property];
        let value2 = b[property];
        return value1 - value2;
    }
}

let  queryByTransactionIds = async function (txIds){
    return new Promise(function(resolve,reject) {
        let headerOpt = {
            "content-type": "application/json",
        };
        let params = {};
        params.transactionIds = txIds;
        let options = {
            uri: config.explorerApiUrl + "/api/v1/txList",
            method: 'POST',
            json: true,
            body: params,
            headers: headerOpt
        };
        request(options, function (error, response, body) {
            if(error){
                reject(error);
            }
            resolve(body);
        });
    });
};

exports.queryByTransactionId = queryByTransactionId;
exports.hashVerify = hashVerify;
exports.save = save;
exports.query = query;
exports.queryWithPagination = queryWithPagination;