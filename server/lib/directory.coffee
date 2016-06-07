path = require 'path'
fs = require 'fs'
rmdir = require 'rimraf'
spawn = require('child_process').spawn

config = require('./conf').get

validName = (name) ->
    name[0] isnt '.' and name.indexOf('/') is -1

###
    Change owner for folder path
###
module.exports.changeOwner = (user, path, callback) ->
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
    unless validName app.name
        callback new Error('Invalid name')
        return
    dirPath = path.join config('dir_app_data'), app.name
    if fs.existsSync dirPath
        # Force the chmod on the folder if the folder previously existed (i.e.
        # if the Cozy is being moved).
        module.exports.changeOwner app.user, dirPath, (err) ->
            callback err
    else
        try
            fs.mkdir dirPath, "0700", (err) ->
                if err
                    callback err
                else
                    module.exports.changeOwner app.user, dirPath, (err) ->
                        callback err
        catch error
            callback error

###
    Remove directory for <app>
###
module.exports.remove = (app, callback) ->
    unless validName app.name
        callback new Error('Invalid name')
        return
    dirPath = path.join config('dir_app_data'), app.name
    if fs.existsSync dirPath
        rmdir dirPath, callback
    else
        callback()
