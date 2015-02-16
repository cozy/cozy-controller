controller = require ('../lib/controller')
async = require 'async'
log = require('printit')()
exec = require('child_process').exec

updateController = (callback) ->
    exec "npm -g update cozy-controller", (err, stdout) ->
        if err
            callback err
        else
            restartController callback

restartController = (callback) ->
    exec "supervisorctl restart cozy-controller", (err, stdout) ->
        if err
            callback "This feature is available only if controller is managed" +
                " by supervisor"
        else
            log.info "Controller was successfully restarted."
            callback()

###
    Install application.
        * Check if application is declared in body.start
        * if application is already installed, just start it
###
module.exports.install = (req, res, next) ->
    if not req.body.start?
        err = new Error "Manifest should be declared in body.start"
        err.status  = 400
        return next err
    manifest = req.body.start
    controller.install req.connection, manifest, (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            err.status  = 400
            next err
        else
            res.send 200, {"drone": {"port": result.port}}

###
    Start application
        * Check if application is declared in body.start
        * Check if application is installed
        * Start application
###
module.exports.start = (req, res, next) ->
    if not req.body.start?
        err = new Error "Manifest should be declared in body.start"
        err.status  = 400
        return next err
    manifest = req.body.start
    controller.start manifest, (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            err.status  = 400
            next err
        else
            res.send 200, {"drone": {"port": result.port}}

###
    Stop application
        * Check if application is installed
        * Stop application
###
module.exports.stop = (req, res, next) ->
    name = req.params.name
    controller.stop name, (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            err.status  = 400
            next err
        else
            res.send 200, app: result

###
    Uninstall application
        * Check if application is installed
        * Uninstall application
###
module.exports.uninstall = (req, res, next) ->
    name = req.params.name
    controller.uninstall name, (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            err.status  = 400
            next err
        else
            res.send 200, app: result

###
    Update application
        * Check if application is installed
        * Update appplication
###
module.exports.update = (req, res, next) ->
    name = req.params.name
    controller.update req.connection, name, (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            err.status  = 400
            next err
        else
            res.send 200, {"drone": {"port": result.port}}

###
    Update application
        * Check if application is installed
        * Update appplication
###
module.exports.updateStack = (req, res, next) ->
    async.eachSeries ['data-system', 'home', 'proxy'], (app, callback) ->
        controller.stop app, (err, res) ->
            return callback err if err?
            controller.update req.connection, app, (err, res) ->
                callback err
    , (err) ->
        if err?
            log.error err.toString()
            err = new Error "Cannot update stack : #{err.toString()}"
            err.status  = 400
            next err
        else
            updateController (err) ->
                if err?
                    log.error err.toString()
                    err = new Error "Cannot update stack : #{err.toString()}"
                    err.status  = 400
                    next err
                else
                    res.send 200

###
    Reboot controller
###
module.exports.restartController = (req, res, next) ->
    restartController (err) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            err.status  = 400
            next err
        else
            res.send 200, {}

###
    Return a list with all applications
###
module.exports.all = (req, res, next) ->
    controller.all (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            err.status  = 400
            next err
        else
            res.send 200, app: result

###
    Return a list with all started applications
###
module.exports.running = (req, res, next) ->
    controller.running (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            err.status  = 400
            next err
        else
            res.send 200, app: result


