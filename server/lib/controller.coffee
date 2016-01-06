fs = require 'fs'
spawner = require './spawner'
npm = require './npm'
repo = require './repo'
directory = require './directory'
user = require './user'
stack = require './stack'
config = require('./conf').get
log = require('printit')
    prefix: 'lib:controller'
type = []
type['git'] = require './git'
App = require('./app').App
path = require 'path'


########################### Global variables ###################################

# drones contains all application
drones = {}
# running contains all started application
running = {}

stackApps = ['home', 'data-system', 'proxy']


############################### Helpers ########################################

###
    Start Application <app>
        * check if application isn't started
        * start process
        * add application in drones and running
###
startApp = (app, callback) ->
    # Start Application
    if running[app.name]?
        # Check if an application with same already exists
        err = new Error 'Application already exists'
        callback err
    else
        # Avoid starting if app is static
        if app.type is 'static'
            callback null, app
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
                    # If app is an stack application,
                    # we store this manifest in stack.json
                    if app.name in stackApps
                        stack.addApp app, (err) ->
                            callback null, result
                    else
                        callback null, result

###
    Stop all applications in tab <apps>
###
stopApps = (apps, callback) ->
    if apps.length > 0
        app = apps.pop()
        stopApp app, ->
            log.info "#{app}:stop application"
            stopApps apps, callback
    else
        drones = []
        callback()

###
    Stop application <name>
        * Stop process
        * Catch event exit (or error)
        * Delete application in running
###
stopApp = (name, callback) ->
    monitor = running[name].monitor
    onStop = ->
        # Avoid double callback
        monitor.removeListener 'error', onErr
        monitor.removeListener 'exit', onStop
        monitor.removeListener 'stop', onStop
        callback null, name
    onErr = (err) ->
        # Avoid double callback
        log.error err
        monitor.removeListener 'stop', onStop
        monitor.removeListener 'exit', onStop
        callback err, name

    monitor.once 'stop', onStop
    monitor.once 'exit', onStop
    monitor.once 'error', onErr
    try
        # Close fd for logs files
        fs.closeSync running[name].fd[0]
        fs.closeSync running[name].fd[1]
    try
        delete running[name]
        #callback null, name
        monitor.stop()
        # Wait event exit to callback
    catch err
        log.error err
        #callback err, name
        onErr err

###
    Update application <name>
        * Recover drone
        * Git pull
        * install new dependencies
###
updateApp = (connection, app, callback) ->
    log.info "#{app.name}:update application"
    type[app.repository.type].update app, (err) ->
        if err?
            callback err
        else
            installDependencies connection, app, 2, (err) ->
                if err?
                    callback err
                else
                    callback null, app


###
    Install depdencies of application <app> <test> times
        * Try to install dependencies (npm install)
        * If installation return an error, try again (if <test> isnt 0)
###
installDependencies = (connection, app, test, callback) ->
    test = test - 1
    npm.install connection, app, (err) ->
        if err? and test is 0
            callback err
        else if err?
            log.info 'TRY AGAIN ...'
            installDependencies connection, app, test, callback
        else
            callback()


############################## Controller ######################################

###
    Remove application <name> from running
        Userfull if application exit with timeout
###
module.exports.removeRunningApp = (name) ->
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
    Error code :
        1 -> Error in user creation
        2- -> Error in code source retrieval
            20 -> Git repo doesn't exist
            21 -> Can"t access to github
            22 -> Git repo exist but it receives an error during clone
        3 -> Error in dependencies installation (npm)
        4 -> Error in application starting
###
module.exports.install = (connection, manifest, callback) ->
    app = new App(manifest).app
    # Check if app exists
    if drones[app.name]? or fs.existsSync(app.dir)
        log.info "#{app.name}:already installed"
        log.info "#{app.name}:start application"
        # Start application
        startApp app, callback
    else
        drones[app.name] = app
        # Create user if necessary
        user.create app, (err) ->
            if err?
                # Error on user creation: code 1
                err.code = 1
                callback err
            else
                # Create repository for application
                directory.create app, (err) ->
                    if err?
                        callback err
                    else
                        # Git clone
                        log.info "#{app.name}:git clone"
                        type[app.repository.type].init app, (err) ->
                            if err?
                                # Error on source retrieval : code 2-
                                err.code ?= 2
                                err.code = 20 + err.code
                                callback err
                            else
                                # NPM install
                                log.info "#{app.name}:npm install"
                                installDependencies connection, app, 2, (err) ->
                                    if err?
                                        # Error on dependencies : code 3
                                        err.code = 3
                                        callback err
                                    # don't need to start if app is static
                                    else if manifest.type is 'static'
                                        callback err, manifest
                                    else
                                        log.info "#{app.name}:start application"
                                        # Start application
                                        startApp app, (err, result)->
                                            # Error application.starting: code 4
                                            err.code = 4 if err?
                                            callback err, result

###
    Start aplication defined by <manifest>
        * Check if application is installed
        * Start process
###
module.exports.start = (manifest, callback) ->
    try
        app = new App(manifest).app
    catch
        return callback new Error "Can't retrieve application manifest, package.json should be JSON format"
    if drones[app.name]? or fs.existsSync(app.dir)
        drones[app.name] = app
        startApp app, (err, result) ->
            if err?
                callback err
            else
                callback null, result
    else
        err = new Error 'Cannot start an application not installed'
        callback err

###
    Change aplication branch
        * Git checkout
        * Install dependencies
###
module.exports.changeBranch = (connection, manifest, newBranch, callback) ->
    # Git checkout
    app = new App(manifest).app
    log.info "#{app.name}:git checkout"
    type['git'].changeBranch app, newBranch, (err) ->
        if err?
            # Error on source retrieval : code 2-
            err.code = 2 if not err.code?
            err.code = 20 + err.code
            callback err
        else
            # NPM install
            log.info "#{app.name}:npm install"
            installDependencies connection, app, 2, (err) ->
                if err?
                    # Error on dependencies : code 3
                    err.code = 3
                    callback err
                else
                    callback()


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
module.exports.uninstall = (name, purge=false, callback) ->
    if drones[name]?
        # Stop application
        if running[name]?
            log.info "#{name}:stop application"
            running[name].monitor.stop()
            delete running[name]

        # If app is an stack application, we store this manifest in stack.json
        if name in stackApps
            log.info "#{name}:remove from stack.json"
            stack.removeApp name, (err) ->
                log.error err if err?
        # Remove repo and log files
        app = drones[name]
        if purge
            log.info "#{name}:delete directory"
            directory.remove app, (err) ->
                log.error err if err?
        # Remove repo
        repo.delete app, (err) ->
            log.info "#{name}:delete source"
            # Remove drone in RAM
            if drones[name]?
                delete drones[name]
            if err?
                callback err
            else
                callback null, name
    else
        userDir = path.join(config('dir_app_bin'), name)
        if fs.existsSync userDir
            app =
                name: name
                dir: userDir
                logFile: config('dir_app_log') + name + ".log"
                errFile: config('dir_app_log') + name + "-err.log"
                backup: config('dir_app_log') + name + ".log-backup"
            if purge
                log.info "#{name}:delete directory"
                directory.remove app, (err) ->
                    log.error err if err?
            repo.delete app, (err) ->
                log.info "#{name}:delete source"
                # Remove drone in RAM
                if drones[name]?
                    delete drones[name]
                if err?
                    callback err
                else
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
module.exports.update = (connection, manifest, callback) ->
    if manifest in stackApps
        manifest = drones[manifest]
    app = new App(manifest).app
    if drones[app.name]?
        if running[app.name]?
            log.info "#{app.name}:stop application"
            stopApp app.name, (err) ->
                updateApp connection, app, (err) ->
                    if err?
                        callback err
                    else
                        startApp app, (err, result) ->
                            log.info "#{app.name}:start application"
                            callback err, result
        else
            updateApp connection, app, callback
    else
        err = new Error 'Application is not installed'
        log.error err
        callback err

###
    Add application <app> in drone
        Usefull for autostart
###
module.exports.addDrone = (app, callback) ->
    drones[app.name] = app
    callback()

###
    Return all applications (started or stopped)
###
module.exports.all = (callback) ->
    apps = {}
    for key in Object.keys(drones)
        apps[key] = drones[key]
    callback null, apps

###
    Return all started applications
###
module.exports.running = (callback) ->
    apps = {}
    for key in Object.keys(running)
        apps[key] = drones[key]
    callback null, apps


