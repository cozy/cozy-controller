americano = require 'americano'
init = require './server/initialize'
controller = require './server/lib/controller'

application = module.exports = (callback) ->
    if process.env.USER? and process.env.USER isnt 'root'
        err = "Are you sure, you are root ?"
        console.log err
        callback(err) if callback?
    else

        options =
            name: 'controller'
            port: process.env.PORT or 9002
            host: process.env.HOST or "127.0.0.1"
            root: __dirname
        init.init (err) =>
            console.log err
            callback(err) if err?

            init.autostart (err) =>
                if not err?
                    americano.start options, callback
                else
                    console.log err
                    callback(err) if callback?

        process.on 'uncaughtException', (err) ->
            console.log err
            console.log err.stack

        process.on 'exit', (code) ->
            console.log "exit"
            controller.stopAll ()=>
                process.exit(code)

        process.on 'SIGTERM', () ->
            console.log "exit"
            controller.stopAll ()=>
                process.exit(code)

if not module.parent
    application()