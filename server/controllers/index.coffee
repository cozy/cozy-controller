# Base controller to return Controller version on the url root.

module.exports =

    index: (req, res, next) ->
        manifest = require '../../../package.json'
        res.send "Cozy Controller version #{manifest.version}"

