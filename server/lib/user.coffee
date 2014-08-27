spawn = require('child_process').spawn
path = require 'path'

module.exports.create = (app, callback) =>    # 
    env = {}
    user = env.USER = app.user
    appdir = env.HOME = app.userDir
    child = spawn('bash', [ path.join(__dirname, '..', 'lib', 'adduser.sh') ], env: env)    

    child.stderr.on 'data', (data) =>
        console.log data.toString()
    child.on 'exit', (code) =>
        if code is 0
            callback()
        else
            callback new Error('Unable to create user')

module.exports.remove = (app, callback) =>    # 
    ## TODOS
    callback()