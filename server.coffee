americano = require 'americano'
init = require './server/initialize'
autostart = require './server/lib/autostart'
controller = require './server/lib/controller'

## Changement de configuration : pas pris en compte

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
            if err?
                console.log "Error during configuration initialization : "
                console.log err
                callback(err)

            autostart.start (err) =>
                if not err?
                    americano.start options, callback
                else
                    console.log "Error during autostart : "
                    console.log err
                    callback(err) if callback?

        process.on 'uncaughtException', (err) ->
            console.log "WARNING : "
            console.log err
            console.log err.stack

        process.on 'exit', (code) ->
            console.log "Process exit"
            controller.stopAll ()=>
                process.exit(code)

        process.on 'SIGTERM', () ->
            console.log "Process is stopped"
            controller.stopAll ()=>
                process.exit(code)

if not module.parent
    application()