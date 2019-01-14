let reqUtils = require('./reqUtils');
let errors = require('./errors');
let invoke = require('./invoke-transaction');
let queryUtil = require('./query');
let helper = require('./helper');
let logger = helper.getLogger('sdkUtils');

/**
 * 数据上链接口
 * @param req
 * @param res
 */
let save = function (req, res) {
    let data = req.body.data;
    //通道名称，默认mychannel
    let channelName = req.body.channelName || "mychannel";
    //智能合约名称，默认trace
    let chaincodeName = req.body.chaincodeName || "trace";
    //父合约
    let parentChaincodeName = req.body.parentChaincodeName || "";
    //peer节点url
    let peersUrls = req.body.peersUrls || ["peer0.org1.example.com"];
    //智能合约方法名
    let functionName = req.body.functionName || "save";
    //用户
    let username = req.username;
    //组织
    let orgName = req.orgname;
    //类名
    let className = req.body.className;
    //父类名
    let parentClassName = req.body.parentClassName || "";
    //数据检查
    if(reqUtils.isEmpty(className)){
        throw new errors.NotFound("className");
    }
    if(reqUtils.isEmpty(data)){
        throw new errors.NotFound("Key data");
    }
    if(!(data instanceof Array)){
        throw new errors.SystemError("data must be an array");
    }
    for (let i = 0; i < data.length; i++) {
        let id = data[i].id;
        if(reqUtils.isEmpty(id)){
            throw new errors.SystemError("id argument must be a non-empty string");
        }
    }

    //返回值
    let promises = [];
    let ret = [];

    //数据上链
    for (let i = 0; i < data.length; i++) {
        let args = [];
        args[0] = className;
        args[1] = data[i].id;
        let jsonObject = {
            "className": className,
            "key": args[1],
            "data": data[i]
        };
        args[2] = JSON.stringify(jsonObject);
        args[3] = parentClassName;
        args[4] = parentChaincodeName;

        let invokePromise = invoke.invokeChaincode(peersUrls, channelName, chaincodeName, functionName, args, username, orgName).then(message => {
            ret.push(message);
        });
        promises.push(invokePromise);
    }
    Promise.all(promises).then(message => {
        res.json(reqUtils.getResponse("操作成功",200,ret));
    }).catch(err => {
        res.json(reqUtils.getErrorMsg(err.message));
    });
};

/**
 * 溯源查询
 * @param req
 * @param res
 * @return {Promise.<void>}
 */
let trace = async function (req, res){
    let queryJson = require("../trace2.json");
    let id = req.body.id;
    richQuery(queryJson,id,{},[],req.username,req.orgname).then(function (message) {
        return res.json(reqUtils.getResponse("操作成功!",200,message[queryJson.className]));
    }).catch(err=>{
        return res.json(reqUtils.getErrorMsg(err));
    })
};

/**
 * 富查询(溯源)
 * @param queryJson
 * @param id
 * @param resultJson
 * @param errors
 * @param username
 * @param orgname
 * @param conditions
 * @return {*}
 */
function richQuery(queryJson,id,resultJson,errors,username,orgname,conditions) {
    if (queryJson === undefined)
        return "Error , queryJson is undefined";
    if (id === undefined)
        return "Error , query id is undefined";
    //类名
    let className = queryJson.className;
    //构造查询语句
    let condition = {};
    if(conditions){
        condition = conditions;
    }else{
        condition.className = className;
        let searchField = queryJson.searchField;
        if (searchField === undefined) {
            condition.Key = id.toString();
        } else {
            condition["data." + searchField] = id;
        }
    }
    console.log(condition);
    return queryChaincode(username,orgname,condition,queryJson.chaincodeName)
        .then((returnJson) => {
            //单次查询结果放入整体查询结果中
            let docs = returnJson;
            if (docs.length > 0) {
                if(queryJson.parentClass){
                    if(!resultJson[className]){
                        resultJson[className] = [];
                    }
                    for (let i = 0; i < docs.length; i++) {
                        resultJson[className].push(docs[i]);
                    }

                    for (let i = 0; i < docs.length; i++) {
                        for(let j = 0 ; j < resultJson[queryJson.parentClass].length; j ++){
                            let parent = resultJson[queryJson.parentClass][j];
                            let doc = docs[i];
                            if(!parent[className]){
                                parent[className] = [];
                            }
                            if(parent[queryJson.sourceField] === doc[queryJson.searchField]){
                                let exist = false;
                                for(let j =0 ; j < parent[className].length ; j ++) {
                                    if (parent[className][j].id === doc.id) {
                                        exist = true;
                                        break;
                                    }
                                }
                                if (!exist) {
                                    parent[className].push(doc);
                                }
                            }
                        }
                    }

                }else{
                    if(!resultJson[className]){
                        resultJson[className] = [];
                    }
                    for (let i = 0; i < docs.length; i++) {
                        resultJson[className].push(docs[i]);
                    }
                }
            } else {
                return resultJson;
            }
            //进行后续查询
            if (queryJson.children === undefined) {
                return resultJson;
            } else {
                let promises = [];
                let len = queryJson.children.length;
                for (let i = 0; i < len; i++) {
                    let child = queryJson.children[i];
                    child.parentClass = className;
                    let sourceField = child.sourceField;

                    for(let j=0;j<docs.length;j++){
                        let condition = child.condition;
                        if(condition && child.className === "room"){
                            condition = {};
                            condition.className = child.className;
                            condition["data.roomId"] = docs[j].roomId;
                            let startTime = docs[j].receiveDate;
                            let endTime = docs[j].sendDate;
                             condition["data.createDate"] = {"$gte": startTime,"$lte": endTime};
                        }
                        promises.push(richQuery(child, docs[j][sourceField],resultJson,errors,username,orgname,condition));
                    }
                }
                //所有异步查询结束后返回
                return Promise.all(promises)
                    .then(function () {
                        if (errors.length === 0) {
                            return resultJson;
                        } else {
                            return "Error," + errors.toString();
                        }
                    })
            }
        });
}

/**
 * 智能合约查询方法(溯源)
 * @param username
 * @param orgname
 * @param selector
 * @param chaincodeName
 * @param peer
 * @param channelName
 * @param fcn
 * @return {Promise.<*>}
 */
let queryChaincode = async function(username,orgname,selector,chaincodeName,peer,channelName,fcn){
    peer =  peer || "peer0.org1.example.com";
    chaincodeName = chaincodeName || "trace";
    channelName = channelName || "mychannel";
    fcn = fcn || "query";
    if (reqUtils.isEmpty(selector)){
        return "Error , queryJson is undefined";
    }

    let args = {};
    args.selector = selector;
    try {
        let datas = await queryUtil.queryChaincode(peer,channelName,chaincodeName,JSON.stringify(args),fcn,username,orgname);
        let ret = [];
        if(!reqUtils.isEmpty(datas)){
            datas = JSON.parse(datas);
            for(let i = 0; i < datas.length ; i++){
                ret.push(datas[i].Record.data);
            }
        }
        return ret;
    }catch (error){
        return error.message;
    }
};

/**
 * 获取总记录数
 * @param username
 * @param orgname
 * @param selector
 * @param chaincodeName
 * @param peer
 * @param channelName
 * @param pageSize
 * @param bookmark
 * @param totalCount
 * @return {Promise.<*>}
 */
let getTotalCount = async function(username,orgname,selector,chaincodeName,peer,channelName,pageSize,bookmark,totalCount){
    peer =  peer || "peer0.org1.example.com";
    chaincodeName = chaincodeName || "trace";
    channelName = channelName || "mychannel";
    let fcn = "queryTotalCount";
    if (reqUtils.isEmpty(selector)){
        return "Error , selector is undefined";
    }

    let args = {};
    args.selector = selector;
    try {
        let datas = await queryUtil.queryChaincode(peer,channelName,chaincodeName,JSON.stringify(args),fcn,username,orgname,pageSize,bookmark);

        let ret = [];
        let response = reqUtils.getResponse("操作成功",200,ret);

        if(!reqUtils.isEmpty(datas)){
            datas = JSON.parse(datas);
            response.totalCount = parseInt(datas.responseMetadata.recordsCount);
            totalCount += response.totalCount;
            if(response.totalCount < pageSize){
                return totalCount;
            }else{
                return getTotalCount(username,orgname,selector,chaincodeName,peer,channelName,pageSize,response.bookmark,totalCount);
            }
        }
    }catch (error){
        return error.message;
    }
};

/**
 * 分页查询
 * @param req
 * @param res
 * @return {Promise.<void>}
 */
let queryWithPagination = async function (req,res) {
    let peer = req.body.peer || "peer0.org1.example.com";
    let chaincodeName = req.body.chaincodeName || "supervision";
    let channelName = req.body.channelName || "mychannel";
    let fcn = "queryWithPagination";
    let selector = req.body.selector;
    let pageSize = req.body.pageSize || 10;
    let bookmark = req.body.bookmark || "";

    let args = {};
    args.selector = selector;
    try {
        let datas = await queryUtil.queryChaincode(peer,channelName,chaincodeName,JSON.stringify(args),fcn,req.username,req.orgname,pageSize,bookmark);

        let ret = [];
        let response = reqUtils.getResponse("操作成功",200,ret);

        if(!reqUtils.isEmpty(datas)){
            datas = JSON.parse(datas);
            response.bookmark = datas.responseMetadata.bookmark;
            response.totalCount = await getTotalCount(req.username,req.orgname,selector,chaincodeName,peer,channelName,100000,"",0);
            for(let i = 0; i < datas.data.length ; i++){
                ret.push(datas.data[i].record.data);
            }
        }
        res.send(response);
    }catch (error){
        res.send(reqUtils.getErrorMsg(error.message));
    }
};

exports.save = save;
exports.queryWithPagination = queryWithPagination;
exports.trace = trace;