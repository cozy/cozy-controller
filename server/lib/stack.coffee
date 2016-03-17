fs = require 'fs'
path = require 'path'
Client = require('request-json-light').JsonClient
log = require('printit')
    date: true
    prefix: 'lib:stack'

config = require('./conf').get
permission = require '../middlewares/token'

controllerAdded = false

dsHost = process.env.DATASYSTEM_HOST or 'localhost'
dsPort = process.env.DATASYSTEM_PORT or 9101

###
    addDatabse:
        * test: number of tests (if app is data-system)
        * app: app to add to database
    Add <app> in database. Try <test> time if app is data-system
    (data-system should be started to add it in database)
###
addDatabase = (attempt, app) ->
    if attempt > 0
        addInDatabase app, (err) ->
            if app.name is 'data-system' and err?
                setTimeout ->
                    addDatabase attempt-1, app
                , 1000

###
    addInDatase:
        * app: application to add to database
    Add <app> in database:
        * Check if application isn't alread store in database
        * If it the case, update it (keep lastVersion added by home)
        * If not, add new document for this application
###
addInDatabase = (app, callback) ->
    clientDS = new Client "http://#{dsHost}:#{dsPort}"
    clientDS.setBasicAuth 'home', permission.get()
    # Check if app already exists
    clientDS.post '/request/stackapplication/all/', {}, (err, res, body) ->
        application = null
        if not err?
            for appli in body
                appli = appli.value
                if appli.name is app.name
                    if application?
                        # Remove if there is several applications
                        requestPath = "data/#{appli._id}/"
                        clientDS.del "data/#{appli._id}/", (err, res, body) ->
                            log.warn err if err?
                    else
                        application = appli
        if application isnt null
            # Application is alread in database
            if application.version is app.version and
                application.git?
                    callback()
            else
                # Keep field lastVersion (added by home)
                app.lastVersion = application.lastVersion
                # Update document if necessary
                requestPath = "data/#{application._id}/"
                clientDS.put requestPath, app, (err, res, body) ->
                    if not err?
                        # Put controllerAdded to true
                        # if application is controller
                        if app.name is 'controller'
                            controllerAdded = true
                    callback err
        else
            # Add new document for application
            clientDS.post '/data/', app, (err, res, body) ->
                err = body.error if not err? and body?.error?
                if not err?
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
        data = JSON.stringify data, null, 2
        fs.writeFile config('file_stack'), data, callback

    ## Store in database
    # Recover application information
    manifest = path.join(config('dir_app_bin'), app.name, 'package.json')
    fs.readFile manifest, (err, data) ->
        if err
            log.warn 'Error when read package.json'
        else
            data = JSON.parse(data)
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
                        log.warn err if err?

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
        data = JSON.stringify data, null, 2
        fs.writeFile config('file_stack'), data, callback
