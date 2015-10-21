path = require "path"
fs = require 'fs'
spawn = require('child_process').spawn
exec = require('child_process').exec
log = require('printit')()
rimraf = require 'rimraf'

pathRoot = "/usr/local/cozy/apps/"

# Check if source has already moved
checkNewSource = (name) ->
    packagePath = path.join(pathRoot, name, "package.json")
    return (name is "stack.json") or fs.existsSync packagePath

# Return source repository of application <name>
getRepo = (name) ->
    mainRepo = path.join(pathRoot, name, name)
    if fs.existsSync mainRepo
        reps = fs.readdirSync mainRepo
        for rep in reps
            if rep.indexOf('.') is -1
                return rep
    else
        rimraf path.join(pathRoot, name), (err) ->
            log.error err if err?
        return []


# Move directory from <source> to <dest>
move = (source, dest, callback) ->
    child = spawn 'sudo', ["mv", source, dest]
    child.stderr.setEncoding('utf8')
    child.stderr.on 'data', (msg) ->
        log.info msg
    child.on 'close', (code) ->
        if code isnt 0
            log.info "Cannot move old source"
            callback "#{name}: Cannot move old source"
        else
            callback()

# Remove directory <dir>
rm = (dir, callback) ->
    child = spawn 'sudo', ["rm", "-rf", dir]
    child.stderr.setEncoding('utf8')
    child.stderr.on 'data', (msg) ->
        log.error msg
    child.on 'close', (code) ->
        if code isnt 0
            log.error "Cannot move old source"
            callback "#{name}: Cannot remove old source"
        else
            log.info "#{dir}: Moved"
            callback()

# Move old source path to new source path
# Old path: /usr/local/cozy/apps/<name>/<name>/<repo>
# New path: /usr/local/cozy/apps/<name>/<repo>
updateSourceDir = (apps, callback) ->
    if apps.length > 0
        name = apps.pop()
        unless checkNewSource(name)
            repo = getRepo(name)
            if repo.length > 0
                # Move old source
                source = path.join(pathRoot, name)
                dest = path.join(pathRoot, "tmp-#{name}")
                move source, dest, (err) ->
                    if err?
                        callback(err)
                    else
                        source = path.join(pathRoot, "tmp-" + name, name, repo)
                        dest = path.join(pathRoot, name)
                        move source, dest, (err) ->
                            if err
                                callback err
                            else
                                appPath = "/usr/local/cozy/apps/tmp-#{name}"
                                rm appPath, (err) ->
                                    if err?
                                        callback err
                                    else
                                        updateSourceDir apps, callback
            else
                updateSourceDir apps, callback
        else
            log.info "#{name}: Already moved"
            updateSourceDir apps, callback
    else
        callback()

# Create stack.json with file stored in autostart of old controller
createStackFile = (callback) ->
    autostartPath = "/usr/local/cozy/autostart"
    if fs.existsSync autostartPath
        stackFile = "/usr/local/cozy/apps/stack.json"
        fs.open stackFile,'w', (err) ->
            files = fs.readdirSync '/usr/local/cozy/autostart/'
            stack = {}
            for file in files
                if file.indexOf('home') isnt -1
                    manifestHome =
                        fs.readFileSync path.join(autostartPath, file), 'utf8'
                    stack.home = JSON.parse manifestHome
                else if file.indexOf('proxy') isnt -1
                    manifestProxy =
                        fs.readFileSync path.join(autostartPath, file), 'utf8'
                    stack.proxy = JSON.parse manifestProxy
                else if file.indexOf('data-system') isnt -1
                    manifestDataSystem =
                        fs.readFileSync path.join(autostartPath, file), 'utf8'
                    stack['data-system'] = JSON.parse manifestDataSystem
            fs.writeFile stackFile, JSON.stringify(stack), callback
    else
        callback()

removeOldDir = (callback) ->
    if fs.existsSync '/etc/cozy/tokens'
        fs.rmdirSync '/etc/cozy/tokens'
    if fs.existsSync '/etc/cozy/controller.token'
        fs.unlinkSync '/etc/cozy/controller.token'
    if fs.existsSync '/usr/local/cozy/config'
        fs.rmdirSync '/usr/local/cozy/config'
    if fs.existsSync '/usr/local/cozy/packages'
        fs.rmdirSync '/usr/local/cozy/packages'
    if fs.existsSync '/usr/local/cozy/tmp'
        fs.rmdirSync '/usr/local/cozy/tmp'
    if fs.existsSync '/etc/cozy/pids'
        rimraf '/etc/cozy/pids', (err) ->
            log.error err if err?
    if fs.existsSync '/usr/local/var/log/cozy'
        rimraf '/usr/local/var/log/cozy', (err) ->
            log.error err if err?
    if fs.existsSync '/usr/local/cozy/autostart'
        rimraf '/usr/local/cozy/autostart', (err) ->
            log.error err if err?
            callback(err)


#update Files -> usefull for patch
module.exports.apply = (callback) ->
    log.info "APPLY patch ..."
    # Update source path
    if fs.existsSync '/etc/cozy/controller.token'
        fs.unlinkSync '/etc/cozy/controller.token'
    dirs = fs.readdirSync '/usr/local/cozy/apps'
    log.info "Move old source directory ..."
    updateSourceDir dirs, (err) ->
        if err?
            log.error err
            callback err
        else
            log.info "Create Stack File ..."
            createStackFile (err) ->
                if err?
                    callback err
                else
                    log.info "Remove old directory ..."
                    removeOldDir (err) ->
                        if err?
                            callback err
                        else
                            callback()