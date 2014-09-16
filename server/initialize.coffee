fs = require 'fs'
Client = require('request-json').JsonClient
spawn = require('child_process').spawn
controller = require './lib/controller'
permission = require './middlewares/token'
App = require('./lib/app').App
conf = require './lib/conf'
config = require('./lib/conf').get
oldConfig = require('./lib/conf').getOld
patch = require './lib/patch'

couchDBClient = new Client 'http://localhost:5984'
clientDS = new Client 'http://localhost:9101'

# Usefull to create stack token
randomString = (length=32) ->
    string = ""
    string += Math.random().toString(36).substr(2) while string.length < length
    string.substr 0, length


############################ Files initialization ##############################

###
    Initialize directory for application source code
###
initNewDir = (callback) =>
    sourceDir = config('dir_source')
    if sourceDir is '/usr/local/cozy/apps'
        if not fs.existsSync '/usr/local/cozy'
            fs.mkdir '/usr/local/cozy', (err) =>
                callback err if err?
                fs.mkdir '/usr/local/cozy/apps', (err) =>
                    callback err
        else if not fs.existsSync '/usr/local/cozy/apps'
            fs.mkdir '/usr/local/cozy/apps', (err) =>
                callback err
        else
            callback()
    else
        callback()

###
    Remove old source directory if configuration has changed
###
removeOldDir = (callback) =>
    newDir = config('dir_source')
    oldDir = oldConfig('dir_source')
    fs.rmdir newDir, (err) =>
        if err?
            callback "Error : source directory doesn't exist"
        else
            fs.rename oldDir, newDir, (err) =>
                callback(err)

###
    Initialize source directory
        * Create new directory
        * Remove old directory if necessary
###
initDir = (callback) =>
    initNewDir (err) =>
        if err?
            callback err
        else
            if oldConfig('dir_source')
                removeOldDir callback
            else
                callback()           

### 
    Initialize source code directory and stack.json file
###
initAppsFiles = (callback) =>
    console.log 'init: source dir'
    stackFile = config('file_stack')
    initDir (err) =>
        callback err if err?
        if oldConfig('file_stack')
            fs.rename oldConfig('file_stack'), stackFile, callback
        else
            if not fs.existsSync stackFile
                fs.open stackFile,'w', callback
            else
                callback()

###
    Initialize directory which contains log files
###
initLogFiles = (callback) =>
    console.log 'init: log files'
    if not fs.existsSync '/var/log/cozy'
        fs.mkdir '/var/log/cozy', (err) =>
            callback(err)
    else
        callback()

###
    Init stack token stored in '/etc/cozy/stack.token'
###
initTokenFile = (callback) =>
    console.log "init : token file"
    tokenFile = config('file_token')
    if tokenFile is '/etc/cozy/stack.token' and not fs.existsSync '/etc/cozy'
        fs.mkdirSync '/etc/cozy'
    if fs.existsSync tokenFile
        fs.unlinkSync tokenFile
    fs.open tokenFile, 'w', (err, fd) =>
        if err
            callback "We cannot create token file. " +
                     "Are you sure, token file configuration is a good path ?"
        else
            fs.chmod tokenFile, '0600', (err) =>
                callback err if err?
                token = randomString()
                fs.writeFile tokenFile, token, (err) =>
                    permission.init(token)
                    callback(err) 

### 
    Initialize files :
        * Initialize configuration
        * Apply patch if necessary
        * Initialize files
###
module.exports.init = (callback) =>
    conf.init (err) =>
        if err
            callback err 
        else
            if conf.patch() is "1"
                patch.apply (err) =>
                    if err
                        callback err
                    else
                        initFiles (err) =>
                            conf.removeOld()
                            callback err
            else
                initFiles callback

### 
    Initialize files :
        * Initialize stack file and directory of source code
        * Initialize log files
        * Initialize token file
###
initFiles = (callback) =>
    initAppsFiles (err) =>
        if err
            callback err
        else
            initLogFiles (err) =>
                conf.removeOld()
                if process.env.NODE_ENV is "production" or 
                    process.env.NODE_ENV is "test"
                        initTokenFile callback
                else
                    callback()


############################### Autostart ######################################

###
    Check if couchDB is started
        * If couchDB isn't startec check again after 5 secondes
        * Return error after <test> (by default 5) tests
###
couchDBStarted = (test=5, callback) =>
    couchDBClient.get '/', (err, res, body) =>
        if not err?
            callback true
        else
            if test > 0
                setTimeout () =>
                    couchDBStarted test-1, callback
                , 5 * 1000
            else
                callback false

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
start = (apps, callback) =>
    if apps? and apps.length > 0
        appli = apps.pop()
        app = appli.value
        app.repository =
            type: "git"
            url: app.git
        app.scripts =
            start: "server.js"
        app.name = app.name.toLowerCase()
        if app.state is "installed"
            console.log("#{app.name}: starting ...")
            controller.start app, (err, result) =>
                if err?
                    console.log("#{app.name}: error")
                    console.log err
                    errors[app.name] = new Error "Application doesn't started" 
                    start apps, callback
                else
                    appli = appli.value
                    appli.port = result.port
                    clientDS.setBasicAuth 'home', permission.get()
                    clientDS.put '/data/', appli, (err, res, body) =>
                        console.log("#{app.name}: started")
                        start apps, callback
        else
            app = new App(app)
            controller.addDrone app.app, () =>
                start apps, callback
    else
        callback()

###
    Check if application is started
        * Try to request application
        * If status code is not 200, 403 or 500 return an error
        (proxy return 500)
###
checkStart = (port, callback) =>
    client = new Client "http://localhost:#{port}"
    client.get "", (err, res) =>
        if res? and res.statusCode in [200, 403, 500]
            if res.statusCode is 500
                console.log "Warning : receives error 500"
            callback()
        else
            checkStart port, callback

###
    Start stack application <app> defined in <data>
        * Check if application is defined in <data>
        * Start application
        * Check if application is started

###
startStack = (data, app, callback) =>
    if data[app]?
        console.log("#{app}: starting ...")
        controller.start data[app], (err, result) =>
            if err? or not result
                console.log err
                err = new Error "#{app} doesn't started"
                callback err
            else
                console.log("#{app}: checking ...")
                timeout = setTimeout () =>
                    callback "[Timeout] #{app} doesn't start"
                , 30000
                checkStart result.port, () ->
                    clearTimeout(timeout)
                    console.log("#{app}: started")
                    setTimeout () =>
                        callback()
                    , 1000
    else
        err = new Error "#{app} isn't installed"
        callback err

###
    Autostart :
        * Stack application are declared in file stack 
            ( /usr/local/cozy/stack.json by default)
        *  Other applications are declared in couchDB
###
module.exports.autostart = (callback) =>
    console.log("### AUTOSTART ###")
    couchDBStarted 5, (started) =>
        if started
            # Start data-system
            console.log('couchDB: started')
            fs.readFile config('file_stack'), 'utf8', (err, data) =>
                if data? or data is ""
                    try
                        data = JSON.parse(data)
                    catch
                        console.log "stack isn't installed"
                        callback()
                        err = true
                    if not err and not data['data-system']?
                        console.log "stack isn't installed"
                        callback()
                        err = true
                    if not err?
                        startStack data, 'data-system', (err) =>
                            if err?
                                callback err
                            else
                                # Start others apps
                                clientDS.setBasicAuth 'home', permission.get()
                                clientDS.post '/request/application/all/', {}, 
                                    (err, res, body) =>
                                        console.log err if err?
                                        start body, (errors) =>
                                            console.log errors if errors isnt {}
                                            #callback err if err
                                            # Start home
                                            startStack data, 'home', (err) =>
                                                console.log err if err?
                                                # Start proxy
                                                startStack data, 'proxy', (err) =>
                                                    console.log err if err?
                                                    callback()       
                else
                    console.log "Cannot read stack file"
                    callback(err)
        else
            err = new Error "couchDB isn't started"
            callback err