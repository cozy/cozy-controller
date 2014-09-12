forever = require 'forever-monitor'
fs = require 'fs'
path = require 'path'
semver = require 'semver'
exec = require('child_process').exec
mixin = require('flatiron').common.mixin
token = require('../middlewares/token')

module.exports.start = (app, callback) ->
    result = {}
    @process.stop() if @process

    # Generate token
    if app.name in ["home", "proxy", "data-system"]
        pwd = token.get()
    else
        pwd = app.password

    # Transmit application's name and token to drone
    env = 
        NAME: app.name
        TOKEN: pwd
        USER: app.user
        USERNAME: app.user
        SUDO_USER: app.user
        HOME: app.userDir
        NODE_ENV: process.env.NODE_ENV

    # Initialize forever options
    foreverOptions = 
        fork:      true
        silent:    true
        max:       5
        stdio:     [ 'ipc', 'pipe', 'pipe' ]
        cwd:       app.dir
        logFile:   app.logFile  
        outFile:   app.logFile 
        errFile:   app.errFile  
        #hideEnv:   env
        env:       env
        killTree:  true
        killTTL:   0
        command:   'node'


    ## Manage logFile and errFile
    if fs.existsSync(app.logFile)
        # If a logFile exists, create a backup
        app.backup = app.logFile + "-backup"
        if fs.existsSync(app.backup)
            fs.unlink app.backup
        fs.rename app.logFile, app.backup
    # Create logFile
    fs.openSync app.logFile, 'w'

    if fs.existsSync(app.errFile)
        # If errFile exists, create a backup
        app.errBackup = app.errFile + "-backup"
        if fs.existsSync(app.errBackup)
            fs.unlink app.errBackup
        fs.rename app.errFile, app.errBackup
    # Create errFile
    fs.openSync app.errFile, 'w'

    # Initialize forever options
    foreverOptions.options = [
        '--plugin',
        'net',
        '--plugin',
        'setuid',
        '--setuid'
        app.user]

        #foreverOptions.command = 'coffee'
    fs.readFile "#{app.dir}/package.json", (err, data) =>
        data = JSON.parse(data)
        if data.scripts?.start?
            start = data.scripts.start.split(' ')
            app.startScript = path.join(app.dir, start[1])

            # Check if server is in coffeescript
            if start[0] is "coffee"
                foreverOptions.options = foreverOptions.options.concat(['--plugin', 'coffee'])
        if not start? and (app.server.slice(server.lastIndexOf("."),app.server.length) is ".coffee")
            foreverOptions.options = foreverOptions.options.concat(['--plugin', 'coffee'])


        # Check if startScript exists
        fs.stat app.startScript, (err, stats) =>
            if err?
                err = new Error "package.json error: can\'t find starting script: #{app.startScript}"
                callback err
        # Initialize process
        foreverOptions.options.push(app.startScript);
        carapaceBin = path.join(require.resolve('cozy-controller-carapace'), '..', '..', 'bin', 'carapace');
        process = new forever.Monitor(carapaceBin, foreverOptions)
        responded = false

        ## Manage events of process

        onExit = () =>
            # Remove listeners to related events.
            process.removeListener 'error', onError
            clearTimeout timeout
            console.log('callback on Exit')
            if callback then callback new Error "#{app.name} CANT START"
            else
                console.log "#{app.name} HAS FAILLED TOO MUCH"
                setTimeout (=> process.exit 1), 1

        onError = (err) =>
            if not responded
                err = err.toString()
                responded = true
                callback err
                process.removeListener 'exit', onExit
                process.removeListener 'message', onPort
                clearTimeout timeout
                #console.log err

        onStart = (monitor, data) =>
            result =
                monitor: process
                process: monitor.child
                data: data
                pid: monitor.childData.pid
                pkg: app

        onRestart = () ->
            console.log "#{app.name}:restart"

        onTimeout = () =>
            process.removeListener 'exit', onExit
            process.stop()

            err = new Error 'Error spawning drone'
            err.stdout = stdout.join('\n');
            err.stderr = stderr.join('\n');

            console.log 'callback timeout'
            callback err

        onPort = (info) =>   
            if not responded and info?.event is 'port'
                responded = true
                result.port = info.data.port
                callback null, result

                # Remove listeners to related events
                process.removeListener 'exit', onExit
                process.removeListener 'error', onError
                process.removeListener 'message', onPort
                clearTimeout timeout

        # Start process
        process.start()

        timeout = setTimeout onTimeout, 8000000

        # Listen to the appropriate events and start the drone process.
        process.once 'exit', onExit
        process.once 'error', onError
        process.once 'start', onStart
        process.on 'restart', onRestart
        process.on 'message', onPort
