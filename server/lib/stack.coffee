fs = require 'fs'
path = require 'path'
Client = require('request-json-light').JsonClient
log = require('printit')()

config = require('./conf').get
permission = require '../middlewares/token'

controllerAdded = false

###
    addDatabse:
        * test: number of tests (if app is data-system)
        * app: app to add to database
    Add <app> in database. Try <test> time if app is data-system
    (data-system should be started to add it in database)
###
addDatabase = (essay, app, callback) ->
    if essay > 0
        addInDatabase app, (err) ->
            if app.name is 'data-system' and err?
                setTimeout () ->
                    addDatabase essay-1, app
                , 1000

###
    addInDatase:
        * app : application to add to database
    Add <app> in database :
        * Check if application isn't alread store in database
        * If it the case, update it (keep lastVersion added by home)
        * If not, add new document for this application
###
addInDatabase = (app, callback) ->
    clientDS = new Client "http://localhost:9101"
    clientDS.setBasicAuth 'home', permission.get()
    # Check if app already exists
    clientDS.post '/request/stackapplication/all/', {}, (err, res, body) ->
        application = null
        if not err?
            for appli in body
                appli = appli.value
                if appli.name is app.name
                    application = appli
        if application isnt null
            # Application is alread in database
            if application.version is app.version
                callback()
            else
                # Keep field lastVersion (added by home)
                app.lastVersion = application.lastVersion
                # Update document if necessary
                clientDS.put "/data/#{application._id}/ ", app, (err, res, body) ->
                    if err?
                        log.warn "Error in updating #{app.name} to database"
                        log.warn err
                    else
                        # Put controllerAdded to true if application is controller
                        if app.name is 'controller'
                            controllerAdded = true
                    callback err
        else
            # Add new document for application
            clientDS.post '/data/', app, (err, res, body) ->
                err = body.error if not err? and body?.error?
                if err?
                    log.warn "Error in adding #{app.name} to database"
                    log.warn err
                else
                    # Put controllerAdded to true if application is controller
                    if app.name is 'controller'
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

    ## Store in database
    # Recover application information
    data = require path.join(config('dir_source'), app.name, 'package.json')
    appli =
        name: app.name
        version: data.version
        git: app.repository.url
        docType: "StackApplication"
    # Add in database
    addDatabase 5, appli
    # If controller isn't already add, add it.
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