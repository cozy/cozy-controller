path = require 'path'
fs = require 'fs'
executeUntilEmpty = require '../helpers/executeUntilEmpty'
config = require('./conf').get
log = require('printit')
    date: true
    prefix: 'lib:npm-installer'

BASE_PACKAGE_JSON = """
    {
      "name": "cozy-controller-apps",
      "version": "1.0.0",
      "description": "Your cozy's Apps will be installed here",
      "README":  "Your cozy's Apps will be installed here",
      "license": "N/A",
      "repository": "N/A"
    }
"""

# we need to create the node_modules manually to give it root:1777
ensureNodeModules = (callback) ->
    folderPath = path.join config('dir_app_bin'), 'node_modules'
    fs.exists folderPath, (exists) ->
        if exists then callback null
        else fs.mkdir folderPath, "1777", (err) ->
            if err then return callback new Error """
                Failed to create folder #{folderPath} : #{err.message}
            """
            # Dont know why the mode in fs.mkdir doesnt get applicated,
            # we get 1733 instead. Force the proper 1777 mode.
            fs.chmod folderPath, '1777', (err) ->
                if err then return callback new Error """
                    Failed to set folder perms #{folderPath} : #{err.message}
                """

                callback null

ensureAppsPackageJSON = (callback) ->
    packagePath = path.join config('dir_app_bin'), 'package.json'
    fs.exists packagePath, (exists) ->
        if exists then callback null
        else fs.writeFile packagePath, BASE_PACKAGE_JSON, 'utf8', (err) ->
            if err
                err = new Error """
                    Failed to create #{packagePath} : #{err.message}"""
            callback err

module.exports.ensureEnvironmentSetup = (callback) ->
    ensureNodeModules (err) ->
        return callback err if err
        ensureAppsPackageJSON callback

###
    Initialize repository of <app>
        * Check if git URL exist
            * URL isn't a Git URL
            * repo doesn't exist in github
        * Clone repo (with one depth)
        * Change branch if necessary
        * Init submodule
###
module.exports.init = (app, callback) ->
    unless app.package?.name
        return callback new Error """
            Tried to npm_installer.init a non NPM app : #{JSON.stringify app}
        """
    commands = [['npm', 'install', app.fullnpmname]]
    console.time "npm installing"
    opts = user: app.user, cwd: config('dir_app_bin')
    executeUntilEmpty commands, opts, (err) ->
        console.timeEnd "npm installing"
        if err?
            log.error err
            log.error "FAILLED TO RUN CMD", err
            callback err
        else
            callback()

###
    Update repository of <app>
        * Reset current changes (due to chmod)
        * Pull changes
        * Update submodule
###
module.exports.update = (app, callback) ->
    commands = [['rm', '-rf', app.dir]]
    opts = cwd: config('dir_app_bin'), user: app.user
    executeUntilEmpty commands, opts, (err) ->
        if err
            log.error err
            log.error "failed to remove app"
        else
            module.exports.init app, callback
###
    Change branch of <app>
###
module.exports.changeBranch = (app, newBranch, callback) ->
    commands = [['rm', '-rf', app.dir]]
    opts = cwd: config('dir_app_bin'), user: app.user
    executeUntilEmpty commands, opts, (err) ->
        if err
            log.error err
            log.error "failed to remove app"
        else
            app.repository.version = newBranch
            module.exports.init app, callback
