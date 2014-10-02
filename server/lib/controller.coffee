fs = require 'fs'
spawner = require './spawner'
npm = require './npm'
repo = require './repo'
user = require './user'
stack = require './stack'
type = []
type['git'] = require './git'
App = require('./app').App


########################### Global variables ###################################

# drones contains all application
drones = []
# running contains all started application
running = []    

stackApps = ['home', 'data-system', 'proxy']


############################### Helpers ########################################

###
    Start Application <app>
        * check if application isn't started
        * start process
        * add application in drones and running 
###
startApp = (app, callback) =>
    # Start Application
    if running[app.name]?
        # Check if an application with same already exists
        callback 'Application already exists'
    else
        # Start application (with spawner)
        spawner.start app, (err, result) ->
            if err?
                callback err
            else if not result?
                err = new Error 'Unknown error from Spawner.'
                callback err
            else
                # Add application in drones and running variables
                drones[app.name] = result.pkg
                running[app.name] = result
                callback null, result

###
    Stop all applications in tab <apps>
###
stopApps = (apps, callback) ->
    if apps.length > 0
        app = apps.pop()
        stopApp app, () ->
            console.log("#{app}:stop application")
            stopApps apps, callback
    else
        callback()

###
    Stop application <name>
        * Stop process
        * Catch event exit (or error)
        * Delete application in running
###
stopApp = (name, callback) =>
    monitor = running[name].monitor
    onStop = () =>
        # Avoid double callback
        monitor.removeListener 'error', onErr
        monitor.removeListener 'exit', onStop
        monitor.removeListener 'stop', onStop
        delete running[name]
        callback null, name
    onErr = (err) =>
        # Avoid double callback
        monitor.removeListener 'stop', onStop
        monitor.removeListener 'exit', onStop
        callback err, name

    monitor.once 'stop', onStop
    monitor.once 'exit', onStop
    monitor.once 'error', onErr
    try 
        monitor.stop()
        # Wait event exit to callback
    catch err
        console.log err
        callback err, name
        onErr err

###
    Install depdencies of application <app> <test> times
        * Try to install dependencies (npm install)
        * If installation return an error, try again (if <test> isnt 0)
###
installDependencies = (app, test, callback) =>
    test = test - 1
    npm.install app, (err) =>
        if err? and test is 0
            callback err
        else if err? 
            installDependencies app, test, callback
        else
            callback()


############################## Controller ######################################

###
    Remove application <name> from running
        Userfull if application exit with timeout
###
module.exports.removeRunningApp = (name) =>
    delete running[name]

###
    Install applicaton defineed by <manifest>
        * Check if application isn't already installed
        * Create user cozy-<name> if necessary
        * Create application repo for source code
        * Clone source in repo
        * Install dependencies
        * If application is a stack application, add application in stack.json
        * Start process
###
module.exports.install = (manifest, callback) =>
    app = new App manifest
    app = app.app
    # Check if app exists
    if drones[app.name]? or fs.existsSync(app.dir)
        console.log("#{app.name}:already installed")
        console.log("#{app.name}:start application")
        # Start application
        startApp app, callback
    else
        # Create user if necessary
        user.create app, () =>
            # Create repo (with permissions)  
            console.log("#{app.name}:create directory")
            repo.create app, (err) =>
                callback err if err?
                # Git clone
                console.log("#{app.name}:git clone")
                type[app.repository.type].init app, (err) =>
                    if err?
                        callback err
                    else
                        # NPM install
                        console.log("#{app.name}:npm install")
                        installDependencies app, 2, (err) =>
                            if err?
                                callback err
                            else                                    
                                console.log("#{app.name}:start application")                                                
                                # If app is an stack application, 
                                # we store this manifest in stack.json
                                if app.name in stackApps  
                                    stack.addApp app, (err) ->
                                        console.log err
                                # Start application
                                drones[app.name] = app
                                startApp app, callback

###
    Start aplication defined by <manifest>
        * Check if application is installed
        * Start process
###
module.exports.start = (manifest, callback) ->
    app = new App manifest
    app = app.app
    if drones[app.name]? or fs.existsSync(app.dir)
        startApp app, (err, result) =>
            if err?
                callback err
            else
                callback null, result
    else
        err = new Error 'Cannot start an application not installed'
        callback err

###
    Stop application <name>
        * Check if application is started
        * Stop process
###
module.exports.stop = (name, callback) ->
    if running[name]?
        stopApp name, callback
    else
        err = new Error 'Cannot stop an application not started'
        callback err

###
    Stop all started applications
        Usefull when controller is stopped
###
module.exports.stopAll = (callback) ->
    stopApps Object.keys(running), callback

###
    Uninstall application <name>
        * Check if application is installed
        * Stop application if appplication is started
        * Remove from stack.json if application is a stack application
        * Remove code source
        * Delete application from drones (and running if necessary)
###
module.exports.uninstall = (name, callback) ->
    if drones[name]?
        # Stop application
        if running[name]?
            console.log("#{name}:stop application")
            running[name].monitor.stop()
            delete running[name]

        # If app is an stack application, we store this manifest in stack.json
        if name in stackApps 
            console.log("#{name}:remove from stack.json")
            stack.removeApp name, (err) ->
                console.log err
        # Remove repo and log files
        app = drones[name]
        # Remove repo
        repo.delete app, (err) =>
            console.log("#{name}:delete directory")
            # Remove drone in RAM
            if drones[name]?
                delete drones[name]
            callback err if err
            callback null, name
    else
        err = new Error 'Cannot uninstall an application not installed'
        callback err


###
    Update an application <name>
        * Check if application is installed
        * Stop application if application is started
        * Update code source (git pull / npm install)
        * Restart application if it was started
###
module.exports.update = (name, callback) ->
    if drones[name]?
        restart = false
        if running[name]?
            console.log("#{name}:stop application")
            stopApp name, callback
            restart = true
        app = drones[name]
        console.log("#{name}:update application")
        type[app.repository.type].update app, (err) =>
            if err?
                callback err
            else
                installDependencies app, 2, (err) =>
                    if err?
                        callback err
                    else    
                        if restart
                            startApp app, (err, result) =>
                                console.log("#{name}:start application")
                                callback err if err?
                                callback null, result
                        else
                            callback null, app
    else
        err = new Error 'Application is not installed'
        console.log err
        callback err

###
    Add application <app> in drone
        Usefull for autostart
###
module.exports.addDrone = (app, callback) ->
    drones[app.name] = app
    callback()

###
    remove drones
        Usefull for tests
###
module.exports.removeDrones = (callback) ->
    drones = []
    running = []
    callback()


###
    Return all applications (started or stopped)
###
module.exports.all = (callback) ->
    callback null, drones

###
    Return all started applications
###
module.exports.running = (callback) ->
    apps = []
    for app in drones
        if running[app.name]?
            apps[app.name] = app
    callback null, apps


