fs = require 'fs'
Client = require('request-json-light').JsonClient
controller = require './controller'
permission = require '../middlewares/token'
path = require 'path'
App = require('./app').App
config = require('./conf').get
log = require('printit')()

couchDBClient = new Client 'http://localhost:5984'

###
    Check if couchDB is started
        * If couchDB isn't startec check again after 5 secondes
        * Return error after <test> (by default 5) tests
###
couchDBStarted = (test=5, callback) ->
    couchDBClient.get '/', (err, res, body) ->
        if not err?
            callback true
        else
            if test > 0
                setTimeout ->
                    couchDBStarted test-1, callback
                , 5 * 1000
            else
                callback false

isCorrect = (app) ->
    return app.git? and app.name? and
        app.state? and
        fs.existsSync(path.join(config('dir_source'), app.name)) and
        fs.existsSync(path.join(config('dir_source'), app.name, "package.json"))

###
    Return manifest of <app> from database application
###
getManifest = (app) ->
    app.repository =
        type: "git"
        url: app.git
    app.name = app.name.toLowerCase()
    return app


# Store all error in application started
errors = {}

###
    Start all applications (other than stack applications)
        * Recover manifest application from document stored in database
        * If it state is 'installed'
            * Start application
            * Check if application is started
            * Update application port in database
        * else
            * Add application in list of installed application
###
start = (apps, clientDS, callback) ->
    if apps? and apps.length > 0
        appli = apps.pop()
        app = getManifest(appli.value)
        if isCorrect(app)
            if app.state is "installed"
                # Start application
                log.info "#{app.name}: starting ..."
                cb = 0
                controller.start app, (err, result) ->
                    cb = cb + 1
                    if err? and cb is 1
                        log.error "#{app.name}: error"
                        log.error err
                        errors[app.name] =
                            new Error "Application didn't started"
                        # Add application if drones list
                        controller.addDrone app, ->
                            start apps, clientDS, callback
                    else
                        # Update port in database
                        appli = appli.value
                        appli.port = result.port
                        clientDS.put '/data/', appli, (err, res, body) ->
                            log.info "#{app.name}: started"
                            start apps, clientDS, callback
            else
                # Add application if drones list
                app = new App(app)
                controller.addDrone app.app, ->
                    start apps, clientDS, callback
        else
            start apps, clientDS, callback
    else
        callback()

###
    Check if application is started
        * Try to request application
        * If status code is not 200, 403 or 500 return an error
        (proxy return 500)
###
checkStart = (port, callback) ->
    client = new Client "http://localhost:#{port}"
    client.get "", (err, res) ->
        if res?
            if res.statusCode not in  [200, 401, 402, 302]
                log.warn "Warning : receives error #{res.statusCode}"
            callback()
        else
            checkStart port, callback

###
    Recover stack applications
        * Read stack file
        * Parse file
        * Return error if file stack doesn't exist
            or if isn't in correct json
        * Return stack manifest
###
recoverStackApp = (callback) ->
    fs.readFile config('file_stack'), 'utf8', (err, data) ->
        if data? or data is ""
            try
                data = JSON.parse(data)
                callback null, data
            catch
                log.info "Stack isn't installed"
                callback "Stack isn't installed"
        else
            log.error "Cannot read stack file"
            callback "Cannot read stack file"

###
    Start stack application <app> defined in <stackManifest>
        * Check if application is defined in <stackManifest>
        * Start application
        * Check if application is started

###
startStack = (stackManifest, app, callback) ->
    if stackManifest[app]?
        log.info "#{app}: starting ..."
        controller.start stackManifest[app], (err, result) ->
            if err? or not result
                log.error "#{app} didn't started"
                log.error err
                err = new Error "#{app} didn't started"
                callback err
            else
                log.info "#{app}: checking ..."
                timeout = setTimeout ->
                    callback "[Timeout] #{app} didn't start"
                , 30000
                checkStart result.port, ->
                    clearTimeout(timeout)
                    log.info "#{app}: started"
                    setTimeout ->
                        callback null, result.port
                    , 1000
    else
        err = new Error "#{app} isn't installed"
        callback()

###
    Autostart :
        * Stack application are declared in file stack
            /usr/local/cozy/stack.json by default
        *  Other applications are declared in couchDB
###
module.exports.start = (callback) ->
    log.info "### AUTOSTART ###"
    couchDBStarted 5, (started) ->
        if started
            # Start data-system
            log.info 'couchDB: started'
            recoverStackApp (err, manifest) ->
                if err?
                    callback()
                else if not manifest['data-system']?
                    log.info "stack isn't installed"
                    callback()
                else
                    startStack manifest, 'data-system', (err, port) ->
                        if err?
                            callback err
                        else
                            # Start others apps
                            clientDS = new Client "http://localhost:#{port}"
                            clientDS.setBasicAuth 'home', permission.get()
                            requestPath = '/request/application/all/'
                            clientDS.post requestPath, {}, (err, res, body) ->
                                if res?.statusCode is 404
                                    callback()
                                else
                                    start body, clientDS, (errors) ->
                                        # Start home
                                        startStack manifest, 'home', (err) ->
                                            log.error err if err?
                                        # Start proxy
                                        startStack manifest, 'proxy', (err) ->
                                            log.error err if err?
                                            callback()
        else
            err = new Error "couchDB isn't started"
            callback err