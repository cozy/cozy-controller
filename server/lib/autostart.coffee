fs = require 'fs'
Client = require('request-json-light').JsonClient
controller = require './controller'
permission = require '../middlewares/token'
path = require 'path'
App = require('./app').App
config = require('./conf').get
log = require('printit')
    date: true
    prefix: 'lib:autostart'
async = require 'async'

dsHost = process.env.DATASYSTEM_HOST or 'localhost'
dsPort = process.env.DATASYSTEM_PORT or 9101
couchdbHost = process.env.COUCH_HOST or 'localhost'
couchdbPort = process.env.COUCH_PORT or '5984'
couchDBClient = new Client "http://#{couchdbHost}:#{couchdbPort}"

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
        fs.existsSync(path.join(config('dir_app_bin'), app.name)) and
        fs.existsSync(path.join(config('dir_app_bin'), app.name, "package.json"))

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

retrievePassword = (app, cb) ->
    clientDS = new Client "http://#{dsHost}:#{dsPort}"
    clientDS.setBasicAuth 'home', permission.get()
    clientDS.post 'request/access/byApp/', key:app._id, (err, res, access) ->
        if not err? and access?[0]?
            cb null, access[0].value.token
        else
            if app.password?
                cb null, app.password
            else
                cb "Can't retrieve application password"

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
start = (appli, callback) ->
    app = getManifest appli.value
    if isCorrect(app)
        retrievePassword app, (err, password) ->
            if err?
                log.error err
            else
                app.password = password
            if app.state is "installed"
                # Start application
                log.info "#{app.name}: starting ..."
                controller.start app, (err, result) ->

                    if err?
                        log.error "#{app.name}: error"
                        log.error err.toString()
                        errors[app.name] =
                            new Error "Application didn't start"
                        # Add application if drones list
                        controller.addDrone app, callback
                    else
                        # Update port in database
                        appli = appli.value
                        appli.port = result.port
                        if not appli.permissions
                            password = appli.password
                            delete appli.password
                        clientDS = new Client "http://#{dsHost}:#{dsPort}"
                        clientDS.setBasicAuth 'home', permission.get()
                        requestPath = "data/merge/#{appli._id}/"
                        clientDS.put requestPath, appli, (err, res, body) ->
                            appli.password = password
                            log.info "#{app.name}: started"
                            callback()

            else
                # Add application if drones list
                app = new App(app)
                controller.addDrone app.app, callback
    else
        callback()

###
    Retrive all applications stored in database
        callback error and applications list
###
getApps = (callback) ->
    clientDS = new Client "http://#{dsHost}:#{dsPort}"
    clientDS.setBasicAuth 'home', permission.get()
    requestPath = '/request/application/all/'
    clientDS.post requestPath, {}, (err, res, body) ->
        if err?
            callback err
        else if res?.statusCode is 404
            callback null, []
        else
            callback null, body

###
    Check if application is started
        * Try to request application
        * If status code is not 200, 403 or 500 return an error
        (proxy return 500)
###
checkStart = (port, callback) ->
    client = new Client "http://#{dsHost}:#{port}"
    client.get "", (err, res) ->
        if res?
            if res.statusCode not in  [200, 401, 402, 302]
                log.warn "Warning: receives error #{res.statusCode}"
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
            catch
                log.info "Stack isn't installed"
                return callback "Stack isn't installed"
            callback null, data
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
                log.error "#{app} didn't start"
                log.error err
                err = new Error "#{app} didn't start"
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
    Autostart:
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
                            dsPort = port
                            # Start others apps
                            getApps (err, apps) ->
                                return callback err if err?
                                async.eachSeries apps, start, (err) ->
                                    # Start proxy
                                    startStack manifest, 'proxy', (err) ->
                                        log.error err if err?
                                        # Start home
                                        startStack manifest, 'home', (err) ->
                                            log.error err if err?
                                            callback()
        else
            err = new Error "couchDB isn't started"
            callback err
