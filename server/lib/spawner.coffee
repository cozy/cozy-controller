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
    @appliProcess.stop() if @appliProcess

    # Generate token
    if app.name in ["home", "proxy", "data-system"]
        pwd = token.get()
    else
        pwd = app.password

    # Transmit application's name and token to appliProcess
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
        # delete previous backup
        if fs.existsSync(app.backup)
            fs.unlinkSync app.backup
        fs.renameSync app.logFile, app.backup
    if fs.existsSync(app.errFile)
        # If a errFile exists, create a backup
        app.backupErr = app.errFile + "-backup"
        if fs.existsSync(app.backupErr)
            fs.unlinkSync app.backupErr
        fs.renameSync app.errFile, app.backupErr
    # Create logFile and errFile
    fd = []
    fd[0] = fs.openSync app.logFile, 'w'
    fd[1] = fs.openSync app.errFile, 'w'

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
        # Initialize application process
        foreverOptions.options.push app.startScript
        carapaceBin = path.join(require.resolve('cozy-controller-carapace'), \
            '..', '..', 'bin', 'carapace')
        appliProcess = new forever.Monitor(carapaceBin, foreverOptions)
        responded = false

        ## Manage events of application process

        onExit = ->
            app.backup = app.logFile + "-backup"
            app.backupErr = app.errFile + "-backup"
            fs.rename app.logFile, app.backup
            fs.rename app.errFile, app.backupErr
            # Remove listeners to related events.
            appliProcess.removeListener 'error', onError
            clearTimeout timeout
            log.error 'Callback on Exit'
            if callback then callback new Error "#{app.name} CANT START"
            else
                log.error "#{app.name} HAS FAILLED TOO MUCH"
                setTimeout (-> appliProcess.exit 1), 1

        onError = (err) ->
            if not responded
                err = err.toString()
                responded = true
                callback err
                appliProcess.removeListener 'exit', onExit
                appliProcess.removeListener 'message', onPort
                clearTimeout timeout

        onStart = (monitor, data) ->
            result =
                monitor: appliProcess
                process: monitor.child
                data: data
                pid: monitor.childData.pid
                pkg: app
                fd: fd

        onRestart = ->
            log.info "#{app.name}:restart"

        onTimeout = ->
            appliProcess.removeListener 'exit', onExit
            appliProcess.stop()
            controller.removeRunningApp(app.name)
            err = new Error 'Error spawning application'
            log.error 'callback timeout'
            callback err

        onPort = (info) ->
            if not responded and info?.event is 'port'
                responded = true
                result.port = info.data.port
                callback null, result

                # Remove listeners to related events
                appliProcess.removeListener 'exit', onExit
                appliProcess.removeListener 'error', onError
                appliProcess.removeListener 'message', onPort
                clearTimeout timeout

        onStderr = (err) ->
            err = err.toString()
            fs.appendFile app.errFile, err, (err) ->
                console.log err if err?


        # Start application process
        appliProcess.start()

        timeout = setTimeout onTimeout, 8000000

        # Listen to the appropriate events and start the application process.
        appliProcess.once 'exit', onExit
        appliProcess.once 'error', onError
        appliProcess.once 'start', onStart
        appliProcess.on 'restart', onRestart
        appliProcess.on 'message', onPort
        appliProcess.on 'stderr', onStderr
