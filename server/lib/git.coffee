path = require 'path'
request = require 'request'
compareVersions = require 'mozilla-version-comparator'
exec = require('child_process').exec
executeUntilEmpty = require '../helpers/executeUntilEmpty'
conf = require('./conf').get
log = require('printit')()

###
    Clean up current modification if the Git URL is wrong
###
onWrongGitUrl = (app, done) ->
    err = new Error "Invalid Git url: #{app.repository.url}"
    err.code = 0
    exec "rm -rf #{app.appDir}", {}, -> done err

###
    Clean up current modification if the Git URL is wrong
###
onBadGitUrl = (app, done) ->
    request.get 'https://github.com', (err, res, body) ->
        if res?.statusCode isnt 200
            err = new Error "Can't access to github"
            err.code = 1
            exec "rm -rf #{app.appDir}", {}, -> done err
        else
            err = new Error "Can't access to git url: #{app.repository.url}"
            err.code = 0
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
                    onBadGitUrl app, callback
                else
                    # Setup the Git commands to be executed
                    commands = []

                    # Default Git branch is "master"
                    branch = app.repository.branch or "master"

                    # 1.7.10 is the version where --single-branch became
                    # available.
                    if not gitVersion? or \
                       compareVersions("1.7.10", gitVersion[1]) is 1
                        commands = [
                            "git clone #{url} #{app.name}"
                            "cd #{app.dir}"
                        ]
                        if branch isnt 'master'
                            commands.push "git branch #{branch} origin/#{branch}"
                            commands.push "git checkout #{branch}"

                    else
                        commands = [
                            "git clone #{url} --depth 1 --branch #{branch} --single-branch #{app.name}"
                            "cd #{app.dir}"
                        ]

                    commands.push "git submodule update --init --recursive"

                    config =
                        cwd: conf('dir_source')
                        user: app.user
                    executeUntilEmpty commands, config, (err) =>
                        if err?
                            log.error err
                            log.info 'Retry to init repository'
                            executeUntilEmpty commands, config, callback
                        else
                            callback()

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

###
    Change branch of <app>
###
module.exports.changeBranch = (app, newBranch, callback) ->

    # Setup the git commands to be executed
    commands = [
        "git fetch origin #{newBranch}:#{newBranch}"
        "git checkout #{newBranch}"
    ]

    config =
        cwd: app.dir # runs all the command in the app's directory
        env: "USER": app.user

    executeUntilEmpty commands, config, callback
