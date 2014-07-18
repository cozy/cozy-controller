path = require "path"
homeDir = '/usr/local/cozy/apps'


class exports.App

    constructor: (@app) ->
        @app.userDir = path.join(homeDir, @app.name)
        @app.appDir = @app.userDir
        @app.user = 'cozy-' + @app.name
        match = app.repository.url.match(/\/([\w\-_\.]+)\.git$/)
        @app.dir = path.join(@app.userDir, match[1])
        @app.server = @app.scripts.start
        @app.startScript = path.join(@app.dir, @app.server)
        @app.logFile = "/var/log/cozy/#{app.name}.log"
        @app.errFile = "/var/log/cozy/#{app.name}.err" 