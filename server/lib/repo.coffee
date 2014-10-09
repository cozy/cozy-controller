fs = require 'fs'
spawn = require('child_process').spawn

###
    Create repository of <app>
        * Create application directory
        * Change directory permissions
        * Chage directory owner
###
module.exports.create = (app, callback) ->
    if app.repository?.type is 'git'
        changeOwner = (path, callback) ->
            child = spawn 'chown', ['-R', app.user, path]
            child.on 'exit', (code) ->
                if code isnt 0
                    callback new Error('Unable to change permissions')
                else
                    callback()
        # check if the user's folder already exists
        fs.stat app.userDir, (userErr, stats) ->
            createAppDir = ->
                # check if the application's folder already exists
                fs.stat app.appDir, (droneErr, stats) ->
                    if droneErr? # folder doesn't exist
                        fs.mkdir app.appDir, "0755", (mkAppErr) ->
                            changeOwner app.appDir, (err) ->
                                if mkAppErr?
                                    callback mkAppErr, false
                    callback null, true

            if userErr?
                fs.mkdir app.userDir, "0755", (mkUserErr) ->
                    changeOwner app.userDir, (err) ->
                        if mkUserErr?
                            callback mkUserErr, false
                        createAppDir()
            else
                createAppDir()
    else
        err = new Error "Controller can spawn only git repo"
        callback err

###
    Delete repository of <app>
        * Remove app directory
        * Remove log files
###
module.exports.delete = (app, callback) ->
    child = spawn 'rm', ['-rf', app.userDir]
    child.on 'exit', (code) ->
        if code isnt 0
            callback new Error('Unable to remove directory')
        else
            fs.unlink app.logFile, (err) ->
                if fs.existsSync app.backup
                    fs.unlink app.backup, (err) ->
                        callback()
                else
                    callback()
