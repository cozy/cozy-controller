fs = require 'fs'

conf = {}

readFile = (callback) =>
    if fs.existsSync '/etc/cozy/controller.json'
        fs.readFile '/etc/cozy/controller.json', (err, data) =>
            try
                data = JSON.parse(data)
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
            callback()



module.exports.get = (arg) =>
    return conf[arg]