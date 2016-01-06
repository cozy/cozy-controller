path = require 'path'
spawn = require('child_process').spawn
log = require('printit')()
config = require('./conf').get

###
  Install dependencies
      * Use strict-ssl or specific npm_registry in function of configuration
      * Npm install
      * Remove npm cache
###
module.exports.install = (connection, target, callback) ->
    args = [
      'npm',
      '--production',
      '--loglevel',
      'info'
      '--unsafe-perm',
      'true',
      '--user',
      target.user
    ]
    if config 'npm_registry'
        args.push '--registry'
        args.push config('npm_registry')
    if config 'npm_strict_ssl'
        args.push '--strict-ssl'
        args.push config('npm_strict_ssl')
    args.push 'install'
    options =
        cwd: target.dir
    child = spawn 'sudo', args, options

    # Kill NPM if this takes more than 10 minutes
    setTimeout(child.kill.bind(child, 'SIGKILL'), 10 * 60 * 1000)

    stderr = ''
    child.stderr.setEncoding 'utf8'
    child.stderr.on 'data', (data) ->
        stderr += data

    child.stdout.setEncoding 'utf8'
    child.stdout.on 'data', (data) ->
        stderr += data
        connection.setTimeout 3 * 60 * 1000

    child.on 'close', (code) ->
        if code isnt 0
            log.error "npm:install:err: NPM Install failed: #{stderr}"
            err = new Error('NPM Install failed')
            callback stderr
        else
            log.info 'npm:install:success'
            callback()
