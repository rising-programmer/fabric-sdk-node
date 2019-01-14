let request = require('request');
let token = "";
let host = "http://localhost:4000";

let path = require('path');
let fs = require('fs');

let dir = "import";

let dirname = path.join(__dirname, dir);
if (!fs.existsSync(dirname)) {
    throw new Error("path not exist");
}

/**
 * 获取token
 */
function getToken(username,orgname){
    return new Promise(function(resolve,reject){
        if(token){
            resolve(token);
            return;
        }
        let params = {};
        //用户名
        params.username = username;
        //组织名
        params.orgName = orgname;
        let options = {
            uri: host+"/api/v1/token",
            method: 'POST',
            json: true,
            body: params
        };
        request(options, function(error,response,body){
            token = body.token;
            resolve(token);
        });
    })
}

/**
 * 数据上链
 * @param data
 * @return {Promise}
 */
async function onechain (data){

    return new Promise(function(resolve,reject) {

        getToken(data.username,data.orgname).then(token => {
            let headerOpt = {
                "content-type": "application/json",
                "Authorization": "Bearer " + token
            };
            let options = {
                uri: host + "/api/v1/save",
                method: 'POST',
                json: true,
                body: data,
                headers: headerOpt
            };
            request(options, function (error, response, body) {
                resolve(JSON.stringify(body));
                token = "";
            });
        })
    });
}

/**
 * 主程序
 * @return {Promise.<void>}
 */
async function main(){
    //因为上链数据有顺序，所以这里分批上链
    let farm = require(dirname + "/" + "farm.json");
    let slaughterhouse = require(dirname + "/" + "slaughterhouse.json");
    let freezingworkshop = require(dirname + "/" + "freezingworkshop.json");
    let aciddrainageworkshop = require(dirname + "/" + "aciddrainageworkshop.json");
    let splitworkshop = require(dirname + "/" + "splitworkshop.json");
    let coldstorage = require(dirname + "/" + "coldstorage.json");
    let coldchaintransporter = require(dirname + "/" + "coldchaintransporter.json");
    let saleterminal = require(dirname + "/" + "saleterminal.json");
    let room = require(dirname + "/" + "room.json");
    let message = await onechain(farm);
    console.log(message);
    message = await onechain(slaughterhouse);
    console.log(message);
    message = await onechain(freezingworkshop);
    console.log(message);
    message = await onechain(aciddrainageworkshop);
    console.log(message);
    message = await onechain(splitworkshop);
    console.log(message);
    message = await onechain(coldstorage);
    console.log(message);
    message = await onechain(coldchaintransporter);
    console.log(message);
    message = await onechain(saleterminal);
    console.log(message);
    message = await onechain(room);
    console.log(message);
}

main();

