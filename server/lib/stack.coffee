fs = require 'fs'
path = require 'path'
Client = require('request-json-light').JsonClient
log = require('printit')()

config = require('./conf').get
permission = require '../middlewares/token'

controllerAdded = false

addInDatabase = (app) ->
    clientDS = new Client "http://localhost:9101"
    clientDS.setBasicAuth 'home', permission.get()
    clientDS.post '/request/stackapplication/all/', {}, (err, res, body) ->
        application = null
        if not err?
            for appli in body
                appli = appli.value
                if appli.name is app.name
                    application = appli
        if application isnt null
            clientDS.put "/data/#{application._id}/ ", app, (err, res, body) ->
                if err?
                    log.warn "Error in updating #{app.name} to database"
                    log.warn err
                else
                    controllerAdded = true
        else
            clientDS.post '/data/', app, (err, res, body) ->
                if err?
                    log.warn "Error in adding #{app.name} to database"
                    log.warn err
                else
                    controllerAdded = true

###
    Add application <app> in stack.json
        * read stack file
        * parse date (in json)
        * add application <app>
        * write stack file with new stack applications
###
module.exports.addApp = (app, callback) ->
    # Store in database
    clientDS = new Client "http://localhost:9101"
    clientDS.setBasicAuth 'home', permission.get()
    app.docType = "StackApplication"
    data = require path.join(config('dir_source'), app.name, 'package.json')
    app.version = data.version
    addInDatabase app
    unless controllerAdded
        data = require path.join __dirname, '..', '..', '..', 'package.json'
        app =
            docType: "StackApplication"
            name:    "controller"
            version: data.version
        addInDatabase app
    # Store in stack.json
    fs.readFile config('file_stack'), 'utf8', (err, data) ->
        try
            data = JSON.parse data
        catch
            data = {}
        data[app.name] = app
        fs.open config('file_stack'), 'w', (err, fd) ->
            fs.write fd, JSON.stringify(data), 0, data.length, 0, callback

###
    Add controller in database
###
module.exports.addController = ->
    # Store in database
    data = require path.join __dirname, '..', '..', '..', 'package.json'
    app =
        docType: "StackApplication"
        name:    "controller"
        version: data.version
    addInDatabase app

###
    Remove application <name> from stack.json
        * read stack file
        * parse date (in json)
        * remove application <name>
        * write stack file with new stack applications
###
module.exports.removeApp = (name, callback) ->
    fs.readFile config('file_stack'), 'utf8', (err, data) ->
        try
            data = JSON.parse data
        catch
            data = {}
        delete data[name]
        fs.open config('file_stack'), 'w', (err, fd) ->
            fs.write fd, JSON.stringify(data), 0, data.length, 0, callback