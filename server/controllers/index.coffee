# Base controller to return Controller version on the url root.

module.exports =

    index: (req, res, next) ->
        try
            manifest = require '../../../package.json' # node build/server.js
        catch
            manifest = require '../../package.json' # coffee server.coffee
        res.send "Cozy Controller version #{manifest.version}"

