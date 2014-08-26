fs = require 'fs'
Client = require('request-json').JsonClient
controller = require './lib/controller'
permission = require './middlewares/token'

couchDBClient = new Client 'http://localhost:5984'
clientDS = new Client 'http://localhost:9101'


randomString = (length=32) ->
    string = ""
    string += Math.random().toString(36).substr(2) while string.length < length
    string.substr 0, length


### Initialize file : /usr/local/cozy/apps, /etc/cozy/controller.token, /var/log/cozy ###
initAppsFiles = (callback) =>
    if not fs.existsSync '/usr/local/cozy'
        fs.mkdir '/usr/local/cozy', (err) =>
            callback err if err?
            fs.mkdir '/usr/local/cozy/apps', (err) =>
                callback err if err?
                fs.open '/usr/local/cozy/apps/stack.json','w', (err) =>
                    callback(err)
    else if not fs.existsSync '/usr/local/cozy/apps'
        fs.mkdir '/usr/local/cozy/apps', (err) =>
            callback err if err?
            fs.open '/usr/local/cozy/apps/stack.json','w', (err) =>
                callback(err)
    else if not fs.existsSync '/usr/local/cozy/apps/stack.json'
        fs.open '/usr/local/cozy/apps/stack.json','w', (err) =>
            callback(err)
    else
        callback()

initLogFiles = (callback) =>
    if not fs.existsSync '/var/log/cozy'
        fs.mkdir '/var/log/cozy', (err) =>
            callback(err)
    else
        callback()

initTokenFile = (callback) =>
    if not fs.existsSync '/etc/cozy'
        fs.mkdirSync '/etc/cozy'
    if fs.existsSync '/etc/cozy/stack.token'
        fs.unlinkSync '/etc/cozy/stack.token'
    fs.open '/etc/cozy/stack.token', 'w', (err, fd) =>
        callback err if err?
        fs.chmod '/etc/cozy/stack.token', '0600', (err) =>
            callback err if err?
            token = randomString()
            fs.writeFile '/etc/cozy/stack.token', token, (err) =>
                permission.init(token)
                callback(err) 

module.exports.init = (callback) =>
    initAppsFiles (err) =>
        initLogFiles (err) =>
            if process.env.NODE_ENV is "production" or process.env.NODE_ENV is "test"
                initTokenFile (err) =>
                    callback()
            else
                callback()

### Autostart ###

couchDBStarted = (test=5) =>
    couchDBClient.get '/', (err, res, body) =>
    if not err?
        return true
    else
        if max < 6
            #sleep test secondes
            return couchDBStarted(max-1)
        else
            return false
errors = {}
start = (apps, callback) =>
    if apps? and apps.length > 0
        app = apps.pop()
        app = app.value
        app.repository =
            type: "git"
            url: app.git
        app.scripts =
            start: "server.js"
        console.log("#{app.name}: starting ...")
        controller.start app, (err, result) =>
            if err?
                console.log("#{app.name}: error")
                errors[app.name] = new Error "Application doesn't started" 
                start apps, callback
            else
                console.log("#{app.name}: started")
                start apps, callback
    else
        callback()

checkStart = (port, callback) =>
    client = new Client "http://localhost:#{port}"
    client.get "", (err, res) =>
        if res? and res.statusCode in [200, 403]
            callback()
        else
            checkStart port, callback

startStack = (data, app, callback) =>
    if data[app]?
        console.log("#{app}: starting ...")
        controller.start data[app], (err, result) =>
            if err? or not result
                err = new Error "#{app} doesn't started"
                callback err
            else
                console.log("#{app}: checking ...")
                timeout = setTimeout () =>
                    callback "[Timeout] Data system doesn't start"
                , 30000
                checkStart result.port, () ->
                    clearTimeout(timeout)
                    console.log("#{app}: started")
                    callback()
    else
        err = new Error "#{app} isn't installed"
        callback err

module.exports.autostart = (callback) =>
    console.log("### AUTOSTART ###")
    if couchDBStarted()
        # Start data-system
        console.log('couchDB: started')
        fs.readFile '/usr/local/cozy/apps/stack.json', 'utf8', (err, data) =>
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
                            clientDS.setBasicAuth 'home', "test"
                            clientDS.post '/request/application/all/', {}, (err, res, body) =>
                                console.log err if err?
                                start body, () =>
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
# Autostart : Stack (dans /usr/local/cozy/stack.json) + apps via couchDB