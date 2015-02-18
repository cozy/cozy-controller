path = require 'path'
request = require 'request'
compareVersions = require 'mozilla-version-comparator'
exec = require('child_process').exec
executeUntilEmpty = require '../helpers/executeUntilEmpty'
conf = require('./conf').get

###
    Clean up current modification if the Git URL is wrong
###
onWrongGitUrl = (app, done) ->
    err = new Error "Invalid Git url: #{app.repository.url}"
    exec "rm -rf #{app.appDir}", {}, -> done err

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
    url = app.repository.url

    # Detects if a string is a valid Git URL
    match = url.match /\/([\w\-_\.]+)\.git$/
    unless match
        # URL isn't a Git url, removes the app's directory
        onWrongGitUrl app, callback
    else
        exec 'git --version', (err, stdout, stderr) ->
            gitVersion = stdout.match /git version ([\d\.]+)/

            # URL without .git
            repoUrl = url.substr 0, (url.length-4)
            request.get repoUrl, (err, res, body) ->

                if res?.statusCode isnt 200
                    # Repo doesn't exist on remote, removes the app's directory
                    onWrongGitUrl app, callback
                else
                    # Setup the Git commands to be executed
                    commands = []

                    # Default Git branch is "master"
                    branch = app.repository.branch or "master"

                    # 1.7.10 is the version where --single-branch became
                    # available.
                    if not gitVersion? or \
                       compareVersions("1.7.10", gitVersion[0]) is -1
                        commands.push "git clone #{url} #{app.name} && " + \
                                      "cd #{app.dir} && " + \
                                      "git checkout #{branch} && " + \
                                      "git submodule update --init --recursive"
                    else
                        commands.push "git clone #{url} --depth 1 " + \
                                      "--branch #{branch} " + \
                                      "--single-branch && " + \
                                      "cd #{app.dir} && " + \
                                      "git submodule update --init --recursive"

                    config =
                        cwd: conf('dir_source')
                        user: app.user
                    executeUntilEmpty commands, config, callback

###
    Update repository of <app>
        * Reset current changes (due to chmod)
        * Pull changes
        * Update submodule
###
module.exports.update = (app, callback) ->

    # Default branch is master
    # branch can store in app.repository (controller manifest) or app.branch (database)
    branch = app.repository.branch or app.branch or "master"

    # Setup the git commands to be executed
    commands = [
        "git reset --hard "
        "git pull origin #{branch}"
        "git submodule update --recursive"
    ]

    config =
        cwd: app.dir # runs all the command in the app's directory
        env: "USER": app.user

    executeUntilEmpty commands, config, callback
