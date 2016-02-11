forever = require 'forever-monitor'
fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
token = require '../middlewares/token'
controller = require '../lib/controller'
log = require('printit')
    date: true
    prefix: 'lib:spawner'
config = require('../lib/conf').get


# Prepare env variables for the app (token, inherited from the controller or
# from the config)
prepareEnv = (app) ->
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
        APPLICATION_PERSISTENT_DIRECTORY: app.folder

    if process.env.DB_NAME?
        env.DB_NAME = process.env.DB_NAME

    # Add specific environment variable for this application
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

    return env


# Prepare the options for forever-monitor and the arguments for
# cozy-controller-carapace
prepareForeverOptions = (app) ->
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

    # Initialize forever options
    foreverOptions.args = [
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
        foreverOptions.args =
            foreverOptions.args.concat(['--bind_ip', config('bind_ip_proxy')])

    return foreverOptions


# Find the command to run to start the app
# The callback is called with 3 parameters:
# - err, the error if the script has not been found
# - startScript, the script to run (if found in package.json)
# - args, some additional arguments to pass on the command line
findStartScript = (app, callback) ->
    fs.readFile "#{app.dir}/package.json", 'utf8', (err, data) ->
        try
            data = JSON.parse(data)
        catch
            return callback new Error "Package.json isn't in a correct format."

        isCoffee = path.extname(app.server) is '.coffee'
        args = []

        if data.scripts?.start?
            start = data.scripts.start.split(' ')
            app.startScript = path.join(app.dir, start[1])
            # Check if server is in coffeescript
            if start[0] is 'coffee'
                isCoffee = true
            args = start[2..]

        # Check if startScript exists
        fs.stat app.startScript, (err, stats) ->
            callback err, isCoffee, args


###
    Start application <app> with forever-monitor and carapace
###
module.exports.start = (app, callback) ->
    result = {}
    env = prepareEnv app
    foreverOptions = prepareForeverOptions app

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


    findStartScript app, (err, isCoffee, foreverArgs) ->
        if err
            callback err
        else
            if isCoffee
                foreverOptions.args =
                    foreverOptions.args.concat(['--plugin', 'coffee'])
            foreverOptions.args.push app.startScript
            foreverOptions.args = foreverOptions.args.concart foreverArgs
            carapaceBin = path.join(
                require.resolve('cozy-controller-carapace'),
                '..', '..', 'bin', 'carapace')
            appliProcess = new forever.Monitor(carapaceBin, foreverOptions)

            responded = false

            ## Manage events of application process
            respond = (err, result) ->
                if not responded
                    responded = true
                    appliProcess.removeListener 'exit', onExit
                    appliProcess.removeListener 'error', onError
                    appliProcess.removeListener 'message', onPort
                    clearTimeout timeout
                    callback err, result

            updateResult = (monitor, data) ->
                result =
                    monitor: appliProcess
                    process: monitor.child
                    data: data
                    pid: monitor.childData.pid
                    pkg: app
                    fd: fd

            onExit = ->
                app.backup = app.logFile + "-backup"
                app.backupErr = app.errFile + "-backup"
                fs.rename app.logFile, app.backup
                fs.rename app.errFile, app.backupErr
                log.error 'Callback on Exit'
                if callback
                    respond new Error "#{app.name} CANT START"
                else
                    log.error "#{app.name} HAS FAILED TOO MUCH"
                    setTimeout (-> appliProcess.exit 1), 1

            onError = (err) ->
                respond err.toString()

            onStart = (monitor, data) ->
                updateResult monitor, data
                log.info "#{app.name}: start with pid #{result.pid}"

            onRestart = (monitor, data) ->
                updateResult monitor, data
                log.info "#{app.name}: restart with pid #{result.pid}"

            onTimeout = ->
                appliProcess.removeListener 'exit', onExit
                appliProcess.stop()
                controller.removeRunningApp(app.name)
                log.error 'callback timeout'
                respond new Error 'Error spawning application'

            onPort = (info) ->
                if info?.event is 'port'
                    result.port = info.data.port
                    respond null, result

            # When an error occured, information is both append to the log
            # file (debugging purpose) and to the error file (to see easily if
            # an error occured).
            onStderr = (err) ->
                err = err.toString()
                fs.appendFile app.logFile, err, (err) ->
                    console.log err if err?
                    fs.appendFile app.errFile, err, (err) ->
                        console.log err if err?


            # Start application process
            appliProcess.start()

            # Listen to the appropriate events and start the application process
            appliProcess.once 'exit', onExit
            appliProcess.once 'error', onError
            appliProcess.once 'start', onStart
            appliProcess.on 'restart', onRestart
            appliProcess.on 'message', onPort
            appliProcess.on 'stderr', onStderr
            timeout = setTimeout onTimeout, 8000000
