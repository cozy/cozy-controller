forever = require 'cozy-forever-monitor'
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

    # Transmit application's name and token to monitor
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
prepareForeverOptions = (app, env) ->
    foreverOptions =
        fork:             true
        silent:           true
        max:              5
        cooldownInterval: 300
        stdio:            [ 'ipc', 'pipe', 'pipe' ]
        cwd:              app.dir
        logFile:          app.logFile
        outFile:          app.logFile
        errFile:          app.errFile
        #hideEnv:          env
        env:              env
        killTree:         true
        killTTL:          0
        command:          'node'

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

        isCoffee = false
        args = []

        if data.scripts?.start?
            start = data.scripts.start.split(' ')
            app.startScript = path.join(app.dir, start[1])
            # Check if server is in coffeescript
            if start[0] is 'coffee'
                isCoffee = true
            args = start[2..]

        unless start
            main = data.main or app.server
            isCoffee = path.extname(main) is '.coffee'

        # Check if startScript exists
        fs.stat app.startScript, (err, stats) ->
            callback err, isCoffee, args


# Delete previous backups and move logs to backups
rotateLogFiles = (app) ->
    if fs.existsSync app.logFile
        # If a logFile exists, create a backup
        app.backup = "#{app.logFile}-backup"

        # delete previous backup
        fs.unlinkSync app.backup if fs.existsSync app.backup
        fs.renameSync app.logFile, app.backup

    if fs.existsSync app.errFile
        # If a errFile exists, create a backup
        app.backupErr = "#{app.errFile}-backup"
        fs.unlinkSync app.backupErr if fs.existsSync app.backupErr
        fs.renameSync app.errFile, app.backupErr


setupLogFiles = (app, foreverOptions) ->
    rotateLogFiles app
    foreverOptions.outFile = app.logFile
    foreverOptions.errFile = app.errFile
    start = (monitor) ->
        # Also send errors to the log file for debugging purpose
        monitor.child.stderr.pipe monitor.stdout, end: false
    close = (monitor) ->
        monitor.child.stderr.unpipe? monitor.stdout
        rotateLogFiles app
    return {start, close}


setupSyslog = (app, foreverOptions) ->
    Syslogger = require 'ain2'
    host = process.env.SYSLOG_HOST or 'localhost'
    port = process.env.SYSLOG_PORT or 514
    logger = new Syslogger hostname: host, port: port
    sendLog = (data) ->
        data = data.toString()
        unless data in [' ', '\n']
            severity = switch data[0..5]
                when 'error:' then 'err'
                when 'warn: ' then 'warn'
                when 'info: ' then 'info'
                when 'debug:' then 'debug'
                else 'notice'
            logger.send data, severity
    start = (monitor) ->
        logger.setMessageComposer (message, severity) ->
            priority = @facility * 8 + severity
            date = @getDate()
            name = app.name
            pid = monitor.childData.pid
            return new Buffer "<#{priority}>#{date} #{name}[#{pid}]:#{message}"
        monitor.on 'stdout', sendLog
        monitor.on 'stderr', sendLog
    close = (monitor) ->
        monitor.removeListener 'stdout', sendLog
        monitor.removeListener 'stderr', sendLog
    return {start, close}


setupLogging = (app, foreverOptions) ->
    if process.env.USE_SYSLOG
        setupSyslog app, foreverOptions
    else
        setupLogFiles app, foreverOptions


###
    Start application <app> with forever-monitor and carapace
###
module.exports.start = (app, callback) ->
    result = {}
    env = prepareEnv app, env
    foreverOptions = prepareForeverOptions app, env
    logging = setupLogging app, foreverOptions

    findStartScript app, (err, isCoffee, foreverArgs) ->
        if err
            callback err
        else
            if isCoffee
                foreverOptions.args =
                    foreverOptions.args.concat(['--plugin', 'coffee'])
            foreverOptions.args.push app.startScript
            foreverOptions.args = foreverOptions.args.concat foreverArgs
            carapaceBin = path.join(
                require.resolve('cozy-controller-carapace'),
                '..', '..', 'bin', 'carapace')
            monitor = new forever.Monitor(carapaceBin, foreverOptions)

            responded = false

            ## Manage events of application process
            respond = (err, result) ->
                if not responded
                    responded = true
                    monitor.removeListener 'exit', onExit
                    monitor.removeListener 'error', onError
                    monitor.removeListener 'message', onPort
                    clearTimeout timeout
                    callback err, result

            onExit = ->
                logging.close monitor
                log.error 'Callback on Exit'
                if callback
                    respond new Error "#{app.name} CANT START"
                else
                    log.error "#{app.name} HAS FAILED TOO MUCH"
                    setTimeout monitor.stop, 1

            onError = (err) ->
                respond err.toString()

            updateResult = (monitor, data) ->
                logging.start monitor
                result =
                    monitor: monitor
                    process: monitor.child
                    data: data
                    pid: monitor.childData.pid
                    pkg: app
                    logging: logging

            onStart = (monitor, data) ->
                updateResult monitor, data
                log.info "#{app.name}: start with pid #{result.pid}"

            onRestart = (monitor, data) ->
                updateResult monitor, data
                log.info "#{app.name}: restart with pid #{result.pid}"

            onTimeout = ->
                monitor.removeListener 'exit', onExit
                monitor.stop()
                controller.removeRunningApp(app.name)
                log.error 'callback timeout'
                respond new Error 'Error spawning application'

            onPort = (info) ->
                if info?.event is 'port'
                    result.port = info.data.port
                    respond null, result

            # Start application process
            monitor.start()

            # Listen to the appropriate events and start the application process
            monitor.once 'exit', onExit
            monitor.once 'error', onError
            monitor.once 'start', onStart
            monitor.on 'restart', onRestart
            monitor.on 'message', onPort
            timeout = setTimeout onTimeout, 8000000
