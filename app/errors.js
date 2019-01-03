let util = require('util');

//Defined a abstract exception that used to be extended by subClasses.
let AbstractError = function (msg, constructor) {
    Error.captureStackTrace(this, constructor || this);
    this.message = msg || 'Error'
};
util.inherits(AbstractError, Error);
AbstractError.prototype.name = 'Abstract Error';

//Not Found Error
let NotFound = function (msg) {
    this.code = 404;
    msg = msg + " is Not Found";
    NotFound.super_.call(this, msg, this.constructor);
};
util.inherits(NotFound, AbstractError);
NotFound.prototype.name = "Not Found Error";

//System Error
let SystemError = function (msg) {
    this.code = 500;
    SystemError.super_.call(this, msg, this.constructor);
};
util.inherits(SystemError, AbstractError);
SystemError.prototype.name = "System Error";

module.exports = {
    NotFound: NotFound,
    SystemError: SystemError,
};