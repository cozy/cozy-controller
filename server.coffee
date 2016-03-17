americano = require 'americano'
init = require './server/initialize'
autostart = require './server/lib/autostart'
controller = require './server/lib/controller'
log = require('printit')
    date: true
    prefix: "server"

application = module.exports = (callback) ->

    # Ensure that user has superuser access.
    if process? and process.getuid() isnt 0

        if process.env?.USER?
            currentUser = ", current user is #{process.env.USER}"
        else
            currentUser = ""
        err = "cozy-controller should be run as root#{currentUser}"
        log.error err
        callback? err

    else
        options =
            name: 'controller'
            port: process.env.PORT or 9002
            host: process.env.HOST or "127.0.0.1"
            root: __dirname

        process.env.NODE_ENV ?= "development"

        init.init (err) ->

            if err?
                log.error "Error during configuration initialization: "
                log.raw err
                callback? err

            autostart.start (err) ->

                if not err?
                    log.info "### Start Cozy Controller ###"
                    americano.start options, (err, app, server) ->
                        log.error err if err

                        server.timeout = 10 * 60 * 1000

                        server.once 'close', (code) ->
                            log.info "Server close with code #{code}."

                            controller.stopAll ->
                                process.removeListener 'uncaughtException', displayError
                                process.removeListener 'exit', exitProcess
                                process.removeListener 'SIGTERM', stopProcess
                                log.info "All applications are stopped"

                        callback? err, app, server
                else
                    log.error "Error during autostart: "
                    log.raw err
                    callback? err

        displayError = (err) ->
            log.warn "WARNING: "
            log.raw err
            log.raw err.stack

        exitProcess = (code) ->
            log.info "Process exit with code #{code}"
            controller.stopAll ->
                process.removeListener 'uncaughtException', displayError
                process.removeListener 'SIGTERM', stopProcess
                process.exit code

        stopProcess = ->
            log.info "Process is stopped"
            controller.stopAll ->
                process.exit()

        process.on 'uncaughtException', displayError
        process.once 'exit', exitProcess
        process.once 'SIGTERM', stopProcess


if not module.parent
    application()
