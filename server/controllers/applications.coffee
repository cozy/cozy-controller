controller = require ('../lib/controller')
async = require 'async'
log = require('printit')
    prefix: 'controllers:applications'
exec = require('child_process').exec
latest = require 'latest'
try
    # Coffee
    pkg = require '../../package.json'
catch
    # JS
    pkg = require '../../../package.json'

sendError = (res, err, code=500) ->
    err ?=
        stack:   null
        message: "Server error occured"

    console.log "Sending error to client: "
    console.log err.stack

    res.send code,
        error: err.message
        success: false
        message: err.message
        stack: err.stack
        code: err.code if err.code?


updateController = (callback) ->
    # Check if a new version is available
    latest 'cozy-controller', (err, version) ->
        if not err? and version isnt pkg.version
            log.info "controller: update"
            exec "npm -g update cozy-controller", (err, stdout, stderr) ->
                if err or stderr
                    callback "Error during controller update: #{stderr}"
                else
                    callback()
        else
            callback()


updateMonitor = (callback) ->
    if @blockMonitor
        callback()
    else
        log.info "monitor: update"
        exec "npm -g update cozy-monitor", (err, stdout, stderr) ->
            if err
                callback "Error during monitor update: #{stderr}"
            else if stderr
                log.warn stderr
                callback()
            else
                callback()

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
        return sendError res, err, 400
    manifest = req.body.start
    controller.install req.connection, manifest, (err, result) ->
        if err?
            log.error err.toString()
            sendError res, err, 400
        else
            # send path to home if it's a static app
            if result.type is 'static'
                res.send 200, drone:
                    "type": result.type
                    "path": result.dir
            else
                res.send 200, drone:
                    "port": result.port

###
    Change application branch.
        * Try to stop application
        * Change application branch
        * Start application if necessary
###
module.exports.changeBranch = (req, res, next) ->
    manifest = req.body.manifest
    name = req.params.name
    newBranch = req.params.branch
    started = true
    # Stop app if it started
    controller.stop name, (err, result) ->
        if err? and err.toString() is 'Error: Cannot stop an application not started'
            # If application is not started, don't restart it after branch change
            started = false
        else if err?
            # If stop function send another error, stop process
            log.error err.toString()
            sendError res, err, 400
        else

            # Change application branch
            conn = req.connection
            controller.changeBranch conn, manifest, newBranch, (err, result) ->
                if err?
                    log.error err.toString()
                    sendError res, err, 400
                else
                    unless started
                        res.send 200, {}

                    # Restart app if necessary
                    else
                        controller.start manifest, (err, result) ->
                            if err?
                                log.error err.toString()
                                sendError res, err, 400
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
        return sendError res, err, 400
    manifest = req.body.start
    controller.start manifest, (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            sendError res, err, 400
        else
            res.send 200, {"drone": {"port": result.port}}

###
    Stop application
        * Check if application is installed
        * Stop application
###
module.exports.stop = (req, res, next) ->
    name = req.params.name
    if req.body.stop.type is 'static'
        res.send 200
    else
        controller.stop name, (err, result) ->
            if err?
                log.error err.toString()
                err = new Error err.toString()
                sendError res, err, 400
            else
                res.send 200, app: result

###
    Uninstall application
        * Check if application is installed
        * Uninstall application
###
module.exports.uninstall = (req, res, next) ->
    name = req.params.name
    purge = req.body.purge?
    controller.uninstall name, purge, (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            sendError res, err, 400
        else
            res.send 200, app: result

###
    Update application
        * Check if application is installed
        * Update appplication
###
module.exports.update = (req, res, next) ->
    manifest = req.body.update
    controller.update req.connection, manifest, (err, result) ->
        if err?
            log.error err.toString()
            err = new Error err.toString()
            sendError res, err, 400
        else
            res.send 200, {"drone": {"port": result.port}}

###
    Update application
        * Check if application is installed
        * Update appplication
###
module.exports.updateStack = (req, res, next) ->
    options = req.body

    async.eachSeries ['data-system', 'proxy', 'home'], (app, callback) ->
        controller.stop app, (err, res) ->
            return callback err if err?
            controller.update req.connection, app, (err, res) ->
                callback err
    , (err) ->
        if err?
            restartController (error) ->
                log.error err.toString()
                err = new Error "Cannot update stack: #{err.toString()}"
                sendError res, err, 400
        else
            async.retry 3, updateMonitor.bind(options), (err, result) ->
                log.error err.toString() if err?
                async.retry 3, updateController, (err, result) ->
                    if err?
                        log.error err.toString()
                        err = new Error "Cannot update stack: #{err.toString()}"
                        sendError res, err, 400
                    else
                        restartController (err) ->
                            if err?
                                log.error err.toString()
                                err = new Error "Cannot update stack: #{err.toString()}"
                                sendError res, err, 400
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
            sendError res, err, 400
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
            sendError res, err, 400
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
            sendError res, err, 400
        else
            res.send 200, app: result


