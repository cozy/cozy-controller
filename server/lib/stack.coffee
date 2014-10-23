fs = require 'fs'
path = require 'path'
Client = require('request-json-light').JsonClient
log = require('printit')()

config = require('./conf').get
permission = require '../middlewares/token'

controllerAdded = false

addDatabase = (test, app, callback) ->
    if test > 0
        addInDatabase app, (err) ->
            if app.name is 'data-system' and err?
                setTimeout () ->
                    addDatabase test-1, app, callback
                , 1000
            else
                callback()
    else
        callback()


addInDatabase = (app, callback) ->
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
            app.lastVersion = application.lastVersion
            app.needsUpdate = application.needsUpdate
            clientDS.put "/data/#{application._id}/ ", app, (err, res, body) ->
                if err?
                    log.warn "Error in updating #{app.name} to database"
                    log.warn err
                else
                    controllerAdded = true
                callback err
        else
            clientDS.post '/data/', app, (err, res, body) ->
                err = body.error if not err? and body?.error?
                if err?
                    log.warn "Error in adding #{app.name} to database"
                    log.warn err
                else
                    controllerAdded = true
                callback err

###
    Add application <app> in stack.json
        * read stack file
        * parse date (in json)
        * add application <app>
        * write stack file with new stack applications
###
module.exports.addApp = (app, callback) ->
    # Store in stack.json
    fs.readFile config('file_stack'), 'utf8', (err, data) ->
        try
            data = JSON.parse data
        catch
            data = {}
        data[app.name] = app
        fs.open config('file_stack'), 'w', (err, fd) ->
            fs.write fd, JSON.stringify(data), 0, data.length, 0, callback

    # Store in database
    data = require path.join(config('dir_source'), app.name, 'package.json')
    appli =
        name: app.name
        version: data.version
        git: app.repository.url
        docType: "StackApplication"
    addDatabase 5, appli, (err) =>
        unless controllerAdded
            controllerPath = path.join __dirname, '..', '..', '..', 'package.json'
            if fs.existsSync controllerPath
                data = require controllerPath
                controller =
                    docType: "StackApplication"
                    name:    "controller"
                    version: data.version
                    git: "https://github.com/cozy/cozy-controller.git"
                addInDatabase controller, (err) ->
                    console.log err if err?

###
    Add controller in database
###
module.exports.addController = ->
    # Store in database
    controllerPath = path.join __dirname, '..', '..', '..', 'package.json'
    if fs.existsSync controllerPath
        data = require controllerPath
        app =
            docType: "StackApplication"
            name:    "controller"
            version: data.version
            git: "https://github.com/cozy/cozy-controller.git"
        addInDatabase app, (err) ->
            console.log err if err?

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