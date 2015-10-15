path = require 'path'
fs = require 'fs'
root = '/usr/local/var/cozy'
spawn = require('child_process').spawn

###
    Create directory for <app>
###
module.exports.create = (app, callback) ->
    changeOwner = (path, callback) ->
        child = spawn 'chown', ['-R', app.user, path]
        child.on 'exit', (code) ->
            if code isnt 0
                callback new Error('Unable to change permissions')
            else
                callback()
    dirPath = path.join root, app.name
    user = app.user
    if fs.existsSync dirPath
        callback()
    else
        try
            fs.mkdir dirPath, "0700", (err) ->
                if err
                    callback err
                else
                    changeOwner dirPath, (err) ->
                        callback err
        catch error
            callback error


###
    Remove appplication directory
###
module.exports.remove = (app, callback) ->
    ## TODOS
    callback()
