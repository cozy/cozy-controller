path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
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


# Generate a file which proxy its args to trueCommmandsFile
makeCommandsProxy = (trueCommandsFile='') ->
    """
    {spawn} = require 'child_process'
    {dirname} = require 'path'
    args = ["#{trueCommandsFile}"].concat process.argv[2..]
    spawn 'coffee', args,
         stdio: 'inherit'
         cwd: dirname "#{trueCommandsFile}"

"""


createAppFolder = (app, callback) ->
    dirPath = path.join config('dir_app_bin'), app.name
    packagePath = path.join dirPath, 'package.json'
    mkdirp dirPath, "0711", (err) ->
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
HACK
A lot of our infra code depends on the /usr/local/cozy/apps/home/commands.coffee
file. This function create a commands.cofee file at the expected location
which proxies its calls to the actual commands.coffee in
/usr/local/cozy/apps/home/node_modules/cozy-home/commands.coffee.
@TODO
- Move all of the commands.coffee commands to the cozy_management
- Use the cozy_management in infra scripts
- Remove this function
###
patchCommandsCoffe = (app, callback) ->
    pname = app.package?.name or app.package
    dirPath = path.join config('dir_app_bin'), app.name
    expectedPath = path.join dirPath, 'commands.coffee'
    truePath = path.resolve dirPath, 'node_modules', pname, 'commands.coffee'
    fs.writeFile expectedPath, makeCommandsProxy(truePath), 'utf8', (err) ->
        return callback err if err
        directory.changeOwner app.user, expectedPath, (err) ->
            return callback err if err
            callback null


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
                patchCommandsCoffe app, callback


###
    Update repository of <app>
        * Run npm install <app> in the apps dir
###
module.exports.update = (app, callback) ->
    commands = [['npm', 'install', app.fullnpmname]]
    appDir = path.join config('dir_app_bin'), app.name

    opts =
        user: app.user
        cwd: appDir

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

