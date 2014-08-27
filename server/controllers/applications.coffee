controller = require ('../lib/controller')


module.exports.install = (req, res, next) =>
    # Install application. 
    # If application is already installed, just start it
    if not req.body.start?
        res.send 400, error: "Manifest should be declared in body.start"
    manifest = req.body.start
    controller.install manifest, (err, result) =>
        if err?
            res.send 400, error:err
        else
            res.send 200, {"drone": {"port": result.port}}


module.exports.start = (req, res, next) ->
    # Start application
    # Send an error if application isn't installed
    if not req.body.start?
        res.send 400, error: "Manifest should be declared in body.start"
    manifest = req.body.start
    controller.start manifest, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, {"drone": {"port": result.port}}


module.exports.stop = (req, res, next) ->
    # Stop application
    # Send an error if application isn't installed
    if not req.body.stop or not req.body.stop.name
        res.send 400, error: "Application name should be declared in body.stop.name"        
    name = req.body.stop.name
    controller.stop name, (err, result) =>
        if err?
            res.send 400, error: err.toString()
        else
            res.send 200, app: result

module.exports.uninstall = (req, res, next) ->
    # Uninstall application
    # Send an error if application isn't installed
    if not req.body.name
        res.send 400, error: "Application name should be declared in body.name"  
    name = req.body.name
    console.log name
    controller.uninstall name, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

module.exports.update = (req, res, next) ->
    # Update application
    # Send an error if application isn't installed
    if not req.body.update or not req.body.update.name
        res.send 400, error: "Application name should be declared in body.update.name"  
    name = req.body.update.name
    controller.update name, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

module.exports.all = (req, res, next) ->
    # Send a liste with all application
    controller.all (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

module.exports.running = (req, res, next) ->
    # Send a liste with all started application
    controller.running (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result


