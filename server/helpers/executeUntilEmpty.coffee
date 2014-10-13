exec = require('child_process').exec

module.exports = executeUntilEmpty = (commands, config, callback) ->

    command = commands.shift()
    # For unknown reason, config.env.USER doesn't work.
    if config.user?
        command = "su #{config.user} -c '#{command}'"
    # Remark: using 'exec' here because chaining 'spawn' is not effective here
    exec command, config, (err, stdout, stderr) ->
        if err?
            callback err, false
        else if commands.length > 0
            executeUntilEmpty commands, config, callback
        else
            callback()