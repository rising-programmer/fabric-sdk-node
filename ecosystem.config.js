module.exports = {
    "apps": [
        {
            "name": "trace_kingland_1",
            "cwd": "/opt/kingland/trace_kingland",
            "script": "app.js",
            "log_date_format": "YYYY-MM-DD HH:mm Z",
            "error_file": "./logs/stderr.log",
            "out_file": "./logs/stdout.log",
            "instances": 1,
            "watch": false,
            "merge_logs": true,
            "exec_interpreter": "node",
            "exec_mode": "fork",
            "autorestart": false,
            "port":"4001"
        },
        {
            "name": "trace_kingland_2",
            "cwd": "/opt/kingland/trace_kingland",
            "script": "app.js",
            "log_date_format": "YYYY-MM-DD HH:mm Z",
            "error_file": "./logs/stderr.log",
            "out_file": "./logs/stdout.log",
            "instances": 1,
            "watch": false,
            "merge_logs": true,
            "exec_interpreter": "node",
            "exec_mode": "fork",
            "autorestart": false,
            "port":"4002"
        },
        {
            "name": "trace_kingland_3",
            "cwd": "/opt/kingland/trace_kingland",
            "script": "app.js",
            "log_date_format": "YYYY-MM-DD HH:mm Z",
            "error_file": "./logs/stderr.log",
            "out_file": "./logs/stdout.log",
            "instances": 1,
            "watch": false,
            "merge_logs": true,
            "exec_interpreter": "node",
            "exec_mode": "fork",
            "autorestart": false,
            "port":"4003"
        },
        {
            "name": "trace_kingland_4",
            "cwd": "/opt/kingland/trace_kingland",
            "script": "app.js",
            "log_date_format": "YYYY-MM-DD HH:mm Z",
            "error_file": "./logs/stderr.log",
            "out_file": "./logs/stdout.log",
            "instances": 1,
            "watch": false,
            "merge_logs": true,
            "exec_interpreter": "node",
            "exec_mode": "fork",
            "autorestart": false,
            "port":"4004"
        }
    ]
}