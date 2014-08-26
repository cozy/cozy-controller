americano = require 'americano'
init = require './server/initialize'
controller = require './server/lib/controller'

application = module.exports = (callback) ->

    options =
        name: 'controller'
        port: process.env.PORT or 9002
        host: process.env.HOST or "127.0.0.1"
        root: __dirname
    init.init () =>
    init.autostart (err) =>
        if not err?
            americano.start options, callback
        else
            console.log err
            callback()

    process.on 'uncaughtException', (err) ->
        console.log err

    process.on 'exit', (code) ->
        controller.stopAll ()=>
            process.exit(code)


if not module.parent
    application()