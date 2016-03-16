path = require "path"
config = require('./conf').get
fs = require 'fs'
log = require('printit')
    date: true
    prefix: 'lib:app'

###
    Useful to translate application stored in database in manifest
###
class exports.App

    constructor: (@app) ->
        binDir = config('dir_app_bin')
        logDir = config('dir_app_log')
        folderDir = config('dir_app_data')

        if @app.package

            # short cut package: "npm-package-name"
            if 'string' is typeof @app.package
                @app.package =
                    type: 'npm'
                    name: @app.package
                    version: 'latest'

            @app.dir = path.join(binDir, 'node_modules', @app.package.name)
            @app.fullnpmname = @app.package.name
            if @app.package.version
                @app.fullnpmname += "@#{@app.package.version}"

        else
            @app.dir = path.join(binDir, @app.name)

        @app.user = 'cozy-' + @app.name
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

        else if fs.existsSync path.join(@app.dir, "package.json")
            try
                manifest = require path.join(@app.dir, "package.json")
            catch error
                if @app?.name?
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
            else if manifest['cozy-type'] is not 'static'
                log.error "Unable to find a start script"

        if @app.server?
            @app.startScript = path.join(@app.dir, @app.server)
