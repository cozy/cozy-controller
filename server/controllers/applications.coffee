controller = require ('../lib/controller')

###
    Install application. 
        * Check if application is declared in body.start
        * if application is already installed, just start it
###
module.exports.install = (req, res, next) =>
    if not req.body.start?
        res.send 400, error: "Manifest should be declared in body.start"
    manifest = req.body.start
    controller.install manifest, (err, result) =>
        if err?
            res.send 400, error:err
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
        res.send 400, error: "Manifest should be declared in body.start"
    manifest = req.body.start
    controller.start manifest, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, {"drone": {"port": result.port}}

###
    Stop application
        * Check if application is installed
        * Stop application
###
module.exports.stop = (req, res, next) ->
    if not req.body?
        name = req.params.slug
    else
        if not req.body.stop or not req.body.stop.name
            err = "Application name should be declared in body.stop.name"   
            res.send 400, error: err
        name = req.body.stop.name
    controller.stop name, (err, result) =>
        if err?
            res.send 400, error: err.toString()
        else
            res.send 200, app: result

###
    Uninstall application
        * Check if application is installed
        * Uninstall application
###
module.exports.uninstall = (req, res, next) ->
    if not req.body?
        name = req.params.slug
    else
        if not req.body.name
            err = "Application name should be declared in body.name"
            res.send 400, error: err
        name = req.body.name
    controller.uninstall name, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

###
    Update application
        * Check if application is installed
        * Update appplication
###
module.exports.update = (req, res, next) ->
    if not req.body.update or not req.body.update.name
        err = "Application name should be declared in body.update.name"
        res.send 400, error: err
    name = req.body.update.name
    controller.update name, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

###
    Return a list with all applications
###
module.exports.all = (req, res, next) ->
    controller.all (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

###
    Return a list with all started applications
###
module.exports.running = (req, res, next) ->
    controller.running (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result


