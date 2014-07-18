path = require 'path'
exec = require('child_process').exec

module.exports.init = (app, callback) =>
    match = app.repository.url.match(/\/([\w\-_\.]+)\.git$/)
    if not match
        err = new Error('Invalid git url: ' + app.repository.url)
        err.blame = 
            type: 'user'   
            message: 'Repository configuration present but provides invalid Git URL'
        callback err

    # Setup the git commands to be executed
    commands = [
        'cd ' + app.appDir + ' && git clone --depth 1 ' + app.repository.url,
        'cd ' + app.dir
    ]

    if app.repository.branch?
        commands[1] += ' && git checkout ' + app.repository.branch

    commands[1] += ' && git submodule update --init --recursive'

    executeUntilEmpty = () =>
        command = commands.shift()
        timeout = setTimeout () =>
            clone.kill 'SIGTERM'
            # Kill all git clone process
            exec 'sudo pkill -9 -f  \'git clone ' + app.repository.url + '\''
            callback err, false
        , 300000

        # Remark: Using 'exec' here because chaining 'spawn' is not effective here
        config =
            env: 
                "USER": app.user
        clone = exec command, config, (err, stdout, stderr) =>
            clearTimeout timeout
            if err?
                callback err, false
            else if commands.length > 0
                executeUntilEmpty()
            else if commands.length is 0
                callback()
    executeUntilEmpty()

module.exports.update = (app, callback) =>  
    match = app.repository.url.match(/\/([\w\-_\.]+)\.git$/)
    if not match
        err = new Error('Invalid git url: ' + app.repository.url)
        err.blame = 
          type: 'user'
          message: 'Repository configuration present but provides invalid Git URL'
        callback err

    # Setup the git commands to be executed
    if app.repository.branch?
        commands = [
            'cd ' + app.dir + ' && git reset --hard ',
            'cd ' + app.dir + ' && git pull origin ' + app.repository.branch,
            'cd ' + app.dir
        ]
    else
        commands = [
            'cd ' + app.dir + ' && git reset --hard ',
            'cd ' + app.dir + ' && git pull',
            'cd ' + app.dir
        ]

    commands[1] += ' && git submodule update --recursive'

    executeUntilEmpty = () =>
        command = commands.shift()

        config =
            env: 
                "USER": app.user
        # Remark: Using 'exec' here because chaining 'spawn' is not effective her
        exec command, config, (err, stdout, stderr) =>
            if err?
                callback err, false
            else if commands.length > 0
                executeUntilEmpty()
            else if commands.length is 0
                callback()
    executeUntilEmpty()