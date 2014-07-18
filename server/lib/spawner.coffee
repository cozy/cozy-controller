forever = require 'forever-monitor'
fs = require 'fs'
path = require 'path'
semver = require 'semver'
exec = require('child_process').exec
mixin = require('flatiron').common.mixin


module.exports.start = (app, callback) ->
    result = {}
    #@process.stop() if @process

    # Generate token
    if app.name in ["home", "proxy", "data-system"]
        token = "test" #haibu.config.get('authToken') || ""
    else
        token = app.password;
    # Transmit application's name and token to drone
    env = 
        NAME: app.name
        TOKEN: token
        USER: app.user
        USERNAME: app.user
        SUDO_USER: app.user
        HOME: app.userDir
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

    # Create log files
    if not fs.existsSync(app.logFile)
        fs.openSync app.logFile, 'w'
    if not fs.existsSync(app.errFile)
        fs.openSync app.errFile, 'w'
    foreverOptions.options = [
        '--plugin',
        'net',
        '--plugin',
        'setuid',
        '--setuid'
        app.user]
    # Check if server is in coffeescript
    if app.server.slice(app.server.lastIndexOf("."),app.server.length) is ".coffee"
        foreverOptions.options = foreverOptions.options.concat(['--plugin', 'coffee'])
        #foreverOptions.command = 'coffee'

    # Check if startScript exists
    fs.stat app.startScript, (err, stats) =>
        if err?
            err = new Error "package.json error: can\'t find starting script: #{app.startScript}"
            callback err
    foreverOptions.options.push(app.startScript);
    carapaceBin = path.join(require.resolve('cozy-controller-carapace'), '..', '..', 'bin', 'carapace');
    process = new forever.Monitor(carapaceBin, foreverOptions)
    responded = false
    #process = new forever.Monitor(app.startScript, foreverOptions)

    # Write output of application in his log file
    onStdout = (data) ->
        data = data.toString()

    onStderr = (data) ->
        data = data.toString()

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
            monitor: monitor
            process: monitor.child
            data: data
            pid: monitor.childData.pid
            pkg: app
        #console.log(data)
        #process.removeListener 'exit', onExit
        #callback null, data, process
        #callback = null # avoid double call

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

    process.start()

    timeout = setTimeout onTimeout, 8000000

    # Listen to the appropriate events and start the drone process.
    process.on 'stdout', onStdout
    process.on 'stderr', onStderr
    process.once 'exit', onExit
    process.once 'error', onError
    process.once 'start', onStart
    process.on 'restart', onRestart
    process.on 'message', onPort
