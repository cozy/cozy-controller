forever = require 'forever-monitor'
fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
token = require '../middlewares/token'
controller = require '../lib/controller'
log = require('printit')()
config = require('../lib/conf').get

###
    Start application <app> with forever-monitor and carapace
###
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
        HOME: app.dir
        NODE_ENV: process.env.NODE_ENV

    if process.env.DB_NAME?
        env.DB_NAME = process.env.DB_NAME

    # Add specific environment varialbe for this application
    # Declared in file configuration
    if config("env")?[app.name]
        environment = config("env")[app.name]
        for key in Object.keys(environment)
            env[key] = environment[key]

    # Add environment variable for all applications
    # Declared in file configuration
    if config("env")?.global
        environment = config("env").global
        for key in Object.keys(environment)
            env[key] = environment[key]

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
        fs.renameSync app.logFile, app.backup
    if fs.existsSync(app.errFile)
        # If a errFile exists, create a backup
        app.backupErr = app.errFile + "-backup"
        if fs.existsSync(app.backupErr)
            fs.unlink app.backupErr
        fs.renameSync app.errFile, app.backupErr
    # Create logFile and errFile
    fs.openSync app.logFile, 'w'
    fs.openSync app.errFile, 'w'

    # Initialize forever options
    foreverOptions.options = [
        '--plugin',
        'net',
        '--plugin',
        'setgid',
        '--setgid'
        app.user,
        '--plugin',
        'setgroups',
        '--setgroups'
        app.user,
        '--plugin',
        'setuid',
        '--setuid'
        app.user]
    if app.name is "proxy"
        foreverOptions.options =
            foreverOptions.options.concat(['--bind_ip', \
               config('bind_ip_proxy')])

        #foreverOptions.command = 'coffee'
    fs.readFile "#{app.dir}/package.json", 'utf8', (err, data) ->
        data = JSON.parse(data)
        server = app.server
        if data.scripts?.start?
            start = data.scripts.start.split(' ')
            app.startScript = path.join(app.dir, start[1])

            # Check if server is in coffeescript
            if start[0] is "coffee"
                foreverOptions.options =
                    foreverOptions.options.concat(['--plugin', 'coffee'])
        if not start? and
                server.slice(server.lastIndexOf("."),server.length) is ".coffee"
            foreverOptions.options =
                foreverOptions.options.concat(['--plugin', 'coffee'])


        # Check if startScript exists
        fs.stat app.startScript, (err, stats) ->
            if err?
                callback err
        # Initialize process
        foreverOptions.options.push app.startScript
        carapaceBin = path.join(require.resolve('cozy-controller-carapace'), \
            '..', '..', 'bin', 'carapace')
        process = new forever.Monitor(carapaceBin, foreverOptions)
        responded = false

        ## Manage events of process

        onExit = ->
            app.backup = app.logFile + "-backup"
            app.backupErr = app.errFile + "-backup"
            fs.rename app.logFile, app.backup
            fs.rename app.errFile, app.backupErr
            # Remove listeners to related events.
            process.removeListener 'error', onError
            clearTimeout timeout
            log.error 'Callback on Exit'
            if callback then callback new Error "#{app.name} CANT START"
            else
                log.error "#{app.name} HAS FAILLED TOO MUCH"
                setTimeout (-> process.exit 1), 1

        onError = (err) ->
            if not responded
                err = err.toString()
                responded = true
                callback err
                process.removeListener 'exit', onExit
                process.removeListener 'message', onPort
                clearTimeout timeout

        onStart = (monitor, data) ->
            result =
                monitor: process
                process: monitor.child
                data: data
                pid: monitor.childData.pid
                pkg: app

        onRestart = ->
            log.info "#{app.name}:restart"

        onTimeout = ->
            process.removeListener 'exit', onExit
            process.stop()
            controller.removeRunningApp(app.name)
            err = new Error 'Error spawning drone'
            log.error 'callback timeout'
            callback err

        onPort = (info) ->
            if not responded and info?.event is 'port'
                responded = true
                result.port = info.data.port
                callback null, result

                # Remove listeners to related events
                process.removeListener 'exit', onExit
                process.removeListener 'error', onError
                process.removeListener 'message', onPort
                clearTimeout timeout

        onStderr = (err) ->
            err = err.toString()
            fs.appendFile app.errFile, err, (err) ->
                console.log err if err?


        # Start process
        process.start()

        timeout = setTimeout onTimeout, 8000000

        # Listen to the appropriate events and start the drone process.
        process.once 'exit', onExit
        process.once 'error', onError
        process.once 'start', onStart
        process.on 'restart', onRestart
        process.on 'message', onPort
        process.on 'stderr', onStderr
