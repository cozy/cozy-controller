spawn = require('child_process').spawn
config = require('./conf').get
path = require 'path'

###
    Create user cozy-<app>
        Use script adduser.sh
###
module.exports.create = (app, callback) ->
    env = {}
    user = env.USER = app.user
    appdir = env.HOME = config('dir_source')
    env.SHELL = process.env.SHELL
    env.PATH = process.env.PATH
    child = spawn 'bash', [ path.join(__dirname, '..', 'lib', 'adduser.sh') ], \
        env: env

    child.on 'exit', (code) ->
        if code is 0
            callback()
        else
            callback new Error('Unable to create user')

###
    Remove appplication user
###
module.exports.remove = (app, callback) ->
    ## TODOS
    callback()
