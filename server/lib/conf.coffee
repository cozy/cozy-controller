fs = require 'fs'

conf = {}
old_conf = {}
patch = "0"

readFile = (callback) =>
    if fs.existsSync '/etc/cozy/controller.json'
        fs.readFile '/etc/cozy/controller.json', 'utf8', (err, data) =>
            try
                console.log data
                data = JSON.parse(data)
                console.log data
                callback null, data
            catch 
                callback "Error : Configuration files isn't a correct json"
    else
        callback null, {}

module.exports.init = (callback) =>
    readFile (err, data) =>
        if err?
            callback err
        else
            if data.old?
                old_conf =
                    dir_log :           data.old.dir_log || false
                    dir_source :        data.old.dir_source || false
                    file_stack :        data.old.file_stack || false
            conf = 
                npm_registry :      data.npm_registry || false
                npm_strict_ssl :    data.npm_strict_ssl || false
                dir_log :           data.dir_log || '/var/log/cozy'
                dir_source :        data.dir_source || '/usr/local/cozy/apps'
                file_token :        data.file_token || '/etc/cozy/stack.token'
                file_stack :        data.file_stack || '/usr/local/cozy/apps/stack.json'
            if data.env?
                conf.env =
                    global:         data.env.global || false
                    data_system:    data.env.data_system || false
                    home:           data.env.home || false
                    proxy:          data.env.proxy || false
            if data.patch?
                patch = data.patch
            callback()

module.exports.get = (arg) =>
    return conf[arg]

module.exports.getOld = (arg) =>
    return old_conf[arg]

module.exports.patch = (arg) =>
    return patch

module.exports.removeOld = () =>  
    if Object.keys(old_conf).length isnt 0
        fs.open "/etc/cozy/controller.json", 'w', (err, fd) =>
            fs.write fd, JSON.stringify(conf), 0, conf.length, 0, () =>
