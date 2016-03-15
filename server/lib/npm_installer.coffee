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
      "author": "",
      "repository": ""
    }
"""

ensureAppsPackageJSON = (callback) ->
    packagePath = path.join config('dir_app_bin'), 'package.json'
    fs.exists packagePath, (exists) ->
        if exists then callback null
        else fs.writeFile packagePath, BASE_PACKAGE_JSON, 'utf8', callback

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
    packageName = app.package.name
    version = app.package.version

    unless packageName
        return callback new Error """
        No field package in app.repository[type=npm] :
          #{JSON.stringify app.repository}
        """

    # Setup the commands to be executed
    fqname = packageName
    fqname += "@#{version}" if version
    commands = [['npm', 'install', fqname]]
    # installPath = path.join config('dir_app_bin'), 'node_modules', packageName
    # # commands.push ['mv', installPath, app.dir]

    ensureAppsPackageJSON (err) ->
        return callback err if err
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
