fs = require 'fs'
spawner = require './spawner'
npm = require './npm'
repo = require './repo'
user = require './user'
stack = require './stack'
type = []
type['git'] = require './git'
App = require('./app').App

# drones contains all application
drones = []
# running contains all started application
running = []    
    
stackApps = ['home', 'data-system', 'proxy']

## Helpers

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

installDependencies = (app, test, callback) =>
    test = test - 1
    npm.install app, (err) =>
        if err? and test is 0
            callback err
        else if err? 
            installDependencies app, test, callback
        else
            callback()

## Controller

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


module.exports.stop = (name, callback) ->
    if running[name]?
        onStop = () =>
            delete running[name]
            callback null, name
        onErr = (err) =>
            callback err, name
        running[name].monitor.once 'stop', onStop
        running[name].monitor.once 'exit', onStop
        running[name].monitor.once 'error', onErr
        try 
            running[name].monitor.stop()
            console.log "callback stop"
        catch err
            console.log err
            callback err, name
            onErr err
    else
        err = new Error 'Cannot stop an application not started'
        callback err

module.exports.stopAll = (callback) ->
    for name in running
        console.log("#{name}:stop application")
        onStop = () =>
            #running[name].removeListener('error', onErr)
            delete running[name]
        onErr = (err) =>
            # Remark should we handle errors here
            running[name].removeListener('stop', onStop)
        running[name].monitor.once 'stop', onStop
        running[name].monitor.once 'exit', onStop
        running[name].monitor.once 'error', onErr
        running[name].monitor.stop()
        delete running[name]

module.exports.uninstall = (name, callback) ->
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
    if drones[name]?
        app = drones[name]
        # Remove repo
        repo.delete app, (err) =>
            console.log("#{name}:delete directory")
            # Remove drone in RAM
            delete drones[name]
            callback err if err
            callback null, name
    else
        err = new Error 'Application is not installed'
        console.log err
        callback err

module.exports.update = (name, callback) ->
    restart = false
    if running[name]?
        console.log("#{name}:stop application")
        running[name].stop()
        restart = true
    app = drones[name]
    console.log("#{name}:update application")
    type[app.repository.type].update app, (err) =>
        callback err if err?
        if restart
            startApp app, (err, result) =>
                console.log("#{name}:start application")
                callback err if err?
                callback null, result
        else
            callback null, app

module.exports.addDrone = (app, callback) ->
    drones[app.name] = app
    callback()

module.exports.all = (callback) ->
    callback null, drones

module.exports.running = (callback) ->
    apps = []
    for app in drones
        if running[app.name]?
            apps[app.name] = app
    callback null, apps


