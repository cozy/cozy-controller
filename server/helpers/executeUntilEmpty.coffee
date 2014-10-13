exec = require('child_process').exec

module.exports = executeUntilEmpty = (commands, config, callback) ->

    command = commands.shift()

    # Remark: using 'exec' here because chaining 'spawn' is not effective here
    exec command, config, (err, stdout, stderr) ->
        if err?
            callback err, false
        else if commands.length > 0
            executeUntilEmpty commands, config, callback
        else
            callback()