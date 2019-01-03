/**
 * method to check if the object is empty
 * @param obj
 * @return {boolean}
 */
module.exports.isEmpty = function (obj) {
    if (obj === null || obj === undefined || obj === "" ) {
        return true;
    }
    return false;
};

/**
 * format http response
 * @param message
 * @param code
 * @param data
 * @return {{code: (*|number), message: *, data: *}}
 */
module.exports.getResponse = function (message, code, data) {
    return {
        "code": code || 200,
        "message": message,
        "data": data
    }
};

/**
 * format http error response
 * @param message
 * @param code
 * @return {{code: (*|number), message: *}}
 */
module.exports.getErrorMsg = function (message, code) {
    return {
        "code": code || 500,
        "message": message
    }
};
