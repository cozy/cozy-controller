path = require "path"
config = require('./conf').get
fs = require 'fs'
log = require('printit')
    date: true

###
    Usefull to translate application stored in database in manifest
###
class exports.App

    constructor: (@app) ->
        homeDir = config('dir_app_bin')
        logDir = config('dir_app_log')
        folderDir = config('dir_app_data')

        @app.dir = path.join(homeDir, @app.name)
        @app.user = 'cozy-' + @app.name
        match = @app.repository.url.match(/\/([\w\-_\.]+)\.git$/)
        @app.logFile = path.join(logDir, "/#{@app.name}.log")
        @app.errFile = path.join(logDir, "/#{@app.name}-err.log")
        @app.folder = path.join folderDir, @app.name

        ## Find server
        # Priority:
        #  * script.start defined in @app
        #  * script.start defined in package.json
        #  * build/server.js (if exsits)
        #  * server.coffee
        if @app.scripts?.start?
            @app.server = @app.scripts.start
        else
            try
                manifest = require path.join(@app.dir, "package.json")
            catch
                if @app.name?
                    log.error "#{@app.name}: Unable to read application manifest"
                else
                    log.error "Unable to read application manifest"
            if manifest?.scripts?.start?
                start = manifest.scripts.start.split(' ')
                @app.server = start[start.length - 1]
            else if fs.existsSync path.join(@app.dir, 'build', 'server.js')
                @app.server = 'build/server.js'
            else if fs.existsSync path.join(@app.dir, 'server.js')
                @app.server = 'server.js'
            else if fs.existsSync path.join(@app.dir, 'server.coffee')
                @app.server = 'server.coffee'
            else
                log.error "Unable to find a start script"

        if @app.server?
            @app.startScript = path.join(@app.dir, @app.server)
