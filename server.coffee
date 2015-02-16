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
        unless process.env.NODE_ENV?
            process.env.NODE_ENV = "development"
        init.init (err) =>
            if err?
                console.log "Error during configuration initialization : "
                console.log err
                callback err if callback?
            autostart.start (err) =>
                if not err?
                    console.log "### START SERVER ###"
                    americano.start options, (app, server) =>

                        server.timeout = 10 * 60 * 1000

                        server.once 'close', (code) ->
                            console.log "Server close with code #{code}"
                            controller.stopAll () =>
                                process.removeListener 'uncaughtException', displayError
                                process.removeListener 'exit', exitProcess
                                process.removeListener 'SIGTERM', stopProcess
                                console.log "All applications are stopped"
                        callback app, server if callback?
                else
                    console.log "Error during autostart : "
                    console.log err
                    callback err  if callback?

        displayError = (err) ->
            console.log "WARNING : "
            console.log err
            console.log err.stack

        exitProcess = (code) ->
            console.log "Process exit with code #{code}"
            controller.stopAll ()=>
                process.removeListener 'uncaughtException', displayError
                process.removeListener 'SIGTERM', stopProcess
                process.exit code

        stopProcess = () ->
            console.log "Process is stopped"
            controller.stopAll ()=>
                process.exit()

        process.on 'uncaughtException', displayError
        process.once 'exit', exitProcess
        process.once 'SIGTERM', stopProcess

if not module.parent
    application()