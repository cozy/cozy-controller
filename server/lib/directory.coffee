path = require 'path'
fs = require 'fs'
config = require('./conf').get
spawn = require('child_process').spawn

###
    Change owner for folder path
###
changeOwner = (user, path, callback) ->
    child = spawn 'chown', ['-R', "#{user}:#{user}", path]
    child.on 'exit', (code) ->
        if code isnt 0
            callback new Error('Unable to change permissions')
        else
            callback()

###
    Create directory for <app>
###
module.exports.create = (app, callback) ->
    dirPath = path.join config('dir_app'), app.name
    user = app.user
    if fs.existsSync dirPath
        callback()
    else
        try
            fs.mkdir dirPath, "0700", (err) ->
                if err
                    callback err
                else
                    changeOwner app.user, dirPath, (err) ->
                        callback err
        catch error
            callback error