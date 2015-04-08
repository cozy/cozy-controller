path = require 'path'
spawn = require('child_process').spawn
log = require('printit')()
config = require('./conf').get
npm = require 'npm'

###
  Install dependencies
      * Use strict-ssl or specific npm_registry in function of configuration
      * Npm install
      * Remove npm cache
###
module.exports.install = (connection, target, callback) ->
    installTimeout = setTimeout () ->
        log.error "npm:install:err: NPM Install failed :Timeout"
        err = new Error('NPM Install failed : timeout')
        callback err
        callback = null
    , 10 * 60 * 1000

    conf =
        'production':true,
        'loglevel':'silent',
        'global': false,
        'unsafe-perm': true
    if config 'npm_registry'
        config.registry = config('npm_registry')
    if config 'npm_strict_ssl'
        config['strict-ssl'] = config('npm_strict_ssl')
    npm.load conf, (err) ->

        npm.prefix = target.dir
        npm.commands.install [], (err) ->
            npm.commands.cache.clean [], (error) ->
                if err
                    clearTimeout installTimeout
                    log.error "npm:install:err: NPM Install failed : #{err}"
                    err = new Error('NPM Install failed')
                    callback err
                else if error
                    clearTimeout installTimeout
                    log.error "npm:install:err: NPM Install failed : #{error}"
                    callback()
                else
                    clearTimeout installTimeout
                    log.info 'npm:install:success'
                    callback()