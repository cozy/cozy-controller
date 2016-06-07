spawn = require('child_process').spawn
config = require('./conf').get
path = require 'path'

###
    Create user cozy-<app>
        Use script adduser.sh
###
module.exports.create = (app, callback) ->
    unless app.user.match /^cozy-[A-Za-z0-9-]+$/
        callback new Error('Invalid username')
        return

    env = {}
    env.USER = app.user

    # XXX app.dir would have been a better $HOME in theory
    # but git can't clone in a folder with things like a `.bashrc`
    env.HOME = config('dir_app_bin')
    env.SHELL = process.env.SHELL
    env.PATH = process.env.PATH

    script = path.join(__dirname, '..', 'lib', 'adduser.sh')
    child = spawn 'sh', [script], env: env
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
