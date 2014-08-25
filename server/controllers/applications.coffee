controller = require ('../lib/controller')


module.exports.install = (req, res, next) =>
    manifest = req.body.star
    controller.install manifest, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, "port": result.port


module.exports.start = (req, res, next) ->
    manifest = req.body.start
    controller.start manifest, (err, result) =>
        if err
            res.send 400, error:err
        else
            console.
            res.send 200, "port": result.port


module.exports.stop = (req, res, next) ->
    name = req.body.stop.name
    controller.stop name, (err, result) =>
        if err?
            res.send 400, error: err.toString()
        else
            res.send 200, app: result

module.exports.uninstall = (req, res, next) ->
    name = req.body.name
    controller.uninstall name, (err, result) =>
        if err
            res.send 400, error:err
        else
            res.send 200, app: result

module.exports.update = (req, res, next) ->
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


