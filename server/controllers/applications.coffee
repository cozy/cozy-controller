controller = require ('../lib/controller')


module.exports.install = (req, res, next) =>
    if not req.body.start?
        res.send 400, error: "Manifest should be declared in body.start"
    ## TODOS : Check if body is correct (start: name/repository.url, ....)
    manifest = req.body.start
    controller.install manifest, (err, result) =>
        if err?
            res.send 400, error:err
        else
            res.send 200, "port": result.port


module.exports.start = (req, res, next) ->
    if not req.body.start?
        res.send 400, error: "Manifest should be declared in body.start"
    manifest = req.body.start
    controller.start manifest, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, "port": result.port


module.exports.stop = (req, res, next) ->
    if not req.body.stop or not req.body.stop.name
        res.send 400, error: "Application name should be declared in body.stop.name"        
    name = req.body.stop.name
    controller.stop name, (err, result) =>
        if err?
            res.send 400, error: err.toString()
        else
            res.send 200, app: result

module.exports.uninstall = (req, res, next) ->
    if not req.body.name
        res.send 400, error: "Application name should be declared in body.name"  
    name = req.body.name
    controller.uninstall name, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

module.exports.update = (req, res, next) ->
    if not req.body.update or not req.body.update.name
        res.send 400, error: "Application name should be declared in body.update.name"  
    name = req.body.update.name
    controller.update name, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

module.exports.all = (req, res, next) ->
    controller.all (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

module.exports.running = (req, res, next) ->
    controller.running (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result


