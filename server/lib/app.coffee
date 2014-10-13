path = require "path"
config = require('./conf').get

###
    Usefull to translate application stored in database in manifest
###
class exports.App

    constructor: (@app) ->
        homeDir = config('dir_source')
        logDir = config('dir_log')

        @app.dir = path.join(homeDir, @app.name)
        @app.user = 'cozy-' + @app.name
        match = @app.repository.url.match(/\/([\w\-_\.]+)\.git$/)
        @app.server = @app.scripts.start
        @app.startScript = path.join(@app.dir, @app.server)
        @app.logFile = path.join(logDir, "/#{app.name}.log")