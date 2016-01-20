sudo = require './sudo'
log = require('printit')()

module.exports = executeUntilEmpty = (commands, config, callback) ->
    command = commands.shift()

    if command[0] is 'cd'
        config.cwd = command[1]
        return executeUntilEmpty commands, config, callback

    child = sudo config.user, config.cwd, command

    stderr = ''
    child.stderr.setEncoding 'utf8'
    child.stderr.on 'data', (data) ->
        stderr += data
    child.stdout.setEncoding 'utf8'
    child.stdout.on 'data', (data) ->
        stderr += data

    child.on 'close', (code) ->
        if code isnt 0
            log.error stderr
            callback new Error "#{command.join ' '} failed with code #{code}"
        else if commands.length > 0
            executeUntilEmpty commands, config, callback
        else
            callback()
