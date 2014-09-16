fs = require 'fs'

## Global variables
conf = {}
oldConf = {}
patch = "0"

###
    Read configuration file
        * Use default configuration if file doesn't exist
        * Return error if configuration file is not a correct json
###
readFile = (callback) =>
    if fs.existsSync '/etc/cozy/controller.json'
        fs.readFile '/etc/cozy/controller.json', 'utf8', (err, data) =>
            try
                data = JSON.parse(data)
                callback null, data
            catch 
                callback "Error : Configuration files isn't a correct json"
    else
        callback null, {}

###
    Initialize configuration
        * Use configuration store in configuration file or default configuration
        * conf : Current configuration
        * oldConf : Old configuration, usefull to move source code between different configurations for example
        * patch : usefull between old and new controller
###
module.exports.init = (callback) =>
    readFile (err, data) =>
        if err?
            callback err
        else
            if data.old?
                oldConf =
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

###
    Return configuration for <arg>
###
module.exports.get = (arg) =>
    return conf[arg]

###
    Return old configuration for <arg>
###
module.exports.getOld = (arg) =>
    return oldConf[arg]

###
    Return patch (is a number) :
        0 -> no patch
        1 -> Patch between haibu and cozy-controller
###
module.exports.patch = (arg) =>
    return patch

###
    Remove Old configuration
        * Rewrite file configuration without old configuration
        * Usefull after changes (move code soource for example)
###
module.exports.removeOld = () =>  
    if Object.keys(oldConf).length isnt 0
        fs.open "/etc/cozy/controller.json", 'w', (err, fd) =>
            fs.write fd, JSON.stringify(conf), 0, conf.length, 0, () =>
