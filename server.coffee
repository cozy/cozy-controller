americano = require 'americano'
init = require './server/initialize'
controller = require './server/lib/controller'

application = module.exports = (callback) ->

    options =
        name: 'controller'
        port: process.env.PORT or 9002
        host: process.env.HOST or "127.0.0.1"
        root: __dirname
    init.init (err) =>
        console.log err
        callback(err) if err?

        init.autostart (err) =>
            console.log err
            if not err?
                americano.start options, callback
            else
                console.log err
                callback()

    process.on 'uncaughtException', (err) ->
        console.log err
        console.log err.stack

    process.on 'exit', (code) ->
        console.log "exit"
        controller.stopAll ()=>
            process.exit(code)

    ###process.on 'close', (code) ->
        controller.stopAll ()=>
            console.log "stop"
            process.exit(code)###

    ###process.on "SIGINT", (code) ->
        console.log "SIGINT"
        controller.stopAll ()=>
            process.exit(code)###



if not module.parent
    application()