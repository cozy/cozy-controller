path = require 'path'
fs = require 'fs'
directory = require './directory'
executeUntilEmpty = require '../helpers/executeUntilEmpty'
config = require('./conf').get
log = require('printit')
    date: true
    prefix: 'lib:npm-installer'

BASE_PACKAGE_JSON = """
    {
      "name": "cozy-controller-fake-package.json",
      "version": "1.0.0",
      "description": "This file is here to please NPM",
      "README":  "This file is here to please NPM",
      "license": "N/A",
      "repository": "N/A"
    }
"""

createAppFolder = (app, callback) ->
    dirPath = path.join config('dir_app_bin'), app.name
    packagePath = path.join dirPath, 'package.json'
    fs.mkdir dirPath, "0700", (err) ->
        if err then return callback new Error """
            Failed to create folder #{dirPath} : #{err.message}
        """
        fs.writeFile packagePath, BASE_PACKAGE_JSON, 'utf8', (err) ->
            if err then return callback new Error """
                Failed to create package.json #{packagePath} : #{err.message}
            """
            directory.changeOwner app.user, dirPath, (err) ->
                if err then return callback new Error """
                    Failed to changeOwner #{dirPath} : #{err.message}
                """
                callback null, dirPath

###
    Initialize repository of <app>
        * Run npm install <app> in the apps dir
###
module.exports.init = (app, callback) ->
    unless app.package?.name
        return callback new Error """
            Tried to npm_installer.init a non NPM app : #{JSON.stringify app}
        """

    createAppFolder app, (err, appFolder) ->
        return callback err if err
        commands = [['npm', 'install', app.fullnpmname]]
        opts = user: app.user, cwd: appFolder
        executeUntilEmpty commands, opts, (err) ->
            if err?
                log.error err
                log.error "FAILLED TO RUN CMD", err
                callback err
            else
                callback()

###
    Update repository of <app>
        * Run npm install <app> in the apps dir
###
module.exports.update = (app, callback) ->
    commands = [['npm', 'install', app.fullnpmname]]
    opts = user: app.user, cwd: config('dir_app_bin')
    executeUntilEmpty commands, opts, (err) ->
        if err
            log.error err
            log.error "failed to remove app"
        else
            callback()
###
    Change branch of <app>
        * Run npm install <app>@<newBranch> in the apps dir
###
module.exports.changeBranch = (app, newBranch, callback) ->
    newFullName = "#{app.package.name}@#{app.package.version}"
    commands = [['npm', 'install', newFullName]]
    opts = cwd: config('dir_app_bin'), user: app.user
    executeUntilEmpty commands, opts, (err) ->
        if err
            log.error err
            log.error "failed to remove app"
        else
            app.package.version = newBranch
            callback()
