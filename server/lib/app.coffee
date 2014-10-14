path = require "path"
config = require('./conf').get
fs = require 'fs'

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
        @app.logFile = path.join(logDir, "/#{app.name}.log")

        ## Find server
        # Priority :
        #  * script.start defined in @app
        #  * script.start defined in package.json
        #  * build/server.js (if exsits)
        #  * server.coffee
        if @app.scripts?.start?
            @app.server = @app.scripts.start
        else
            manifest = require path.join(@app.dir, "package.json")
            if manifest.scripts?.start?
                start = manifest.scripts.start.split(' ')
                @app.server = start[start.length - 1]
            else if fs.existsSync path.join(@app.dir, 'build', 'server.js')
                @app.server = 'build/server.js'
            else
                @app.server = 'server.coffee'
        @app.startScript = path.join(@app.dir, @app.server)
