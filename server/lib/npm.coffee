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
module.exports.install = (target, callback) ->
    args = [
      'npm'
      '--production'
    ]
    if config 'npm_registry'
        args.push '--registry'
        args.push config('npm_registry')
    if config 'npm_strict_ssl'
        args.push '--strict-ssl'
        args.push config('npm_strict_ssl')
    args.push 'install'
    args.push '--user'
    args.push target.user
    options =
        cwd: target.dir
    child = spawn 'sudo', args, options

    # Kill NPM if this takes more than 5 minutes
    setTimeout(child.kill.bind(child, 'SIGKILL'), 5 * 60 * 1000)

    #child.stdout.on 'data', (data) =>
    stderr = ''
    child.stderr.on 'data', (data) ->
        stderr += data

    child.on 'close', (code) ->
        if code isnt 0
            log.error "npm:install:err: NPM Install failed : #{stderr}"
            err = new Error('NPM Install failed')
            callback err
        else
            log.info 'npm:install:success'
            callback()