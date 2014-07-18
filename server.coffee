americano = require 'americano'
init = require './server/initialize'

application = module.exports = (callback) ->

    options =
        name: 'controller'
        port: process.env.PORT or 9002
        host: process.env.HOST or "127.0.0.1"
        root: __dirname

    init.init () =>
    init.autostart (err) => 
        if not err?
            americano.start options, (app, server) ->
        else
            console.log err

if not module.parent
    application()