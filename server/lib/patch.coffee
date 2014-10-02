path = require "path"
fs = require 'fs'
spawn = require('child_process').spawn

pathRoot = "/usr/local/cozy/apps/"

# Check if source has already moved
checkOldSource = (name) =>
    return (fs.existsSync path.join(pathRoot, name, name)) and 
        (not fs.existsSync path.join(pathRoot, name, name, "server.coffee")) and
        (name isnt "stack.json")

# Return source repository of application <name> 
getRepo = (name) =>
    reps = fs.readdirSync path.join(pathRoot, name, name)
    for rep in reps
        if rep.indexOf('.') is -1
            return rep

# Move directory from <source> to <dest>
move = (source, dest, callback) ->
    child = spawn 'sudo', ["mv", source, dest]
    child.stderr.setEncoding('utf8')
    child.stderr.on 'data', (msg) =>
        console.log msg
    child.on 'close', (code) =>
        if code isnt 0
            console.log("Cannot move old source")
            callback "#{name} : Cannot move old source"
        else   
            callback()

# Remove directory <dir>
rm = (dir, callback) ->
    child = spawn 'sudo', ["rm", "-rf", dir]
    child.stderr.setEncoding('utf8')
    child.stderr.on 'data', (msg) =>
        console.log msg
    child.on 'close', (code) =>
        if code isnt 0
            console.log("Cannot move old source")
            callback "#{name} : Cannot remove old source"
        else
            console.log "#{dir} : Moved"
            callback()

# Move old source path to new source path
# Old path : /usr/local/cozy/apps/<name>/<name>/<repo>
# New path : /usr/local/cozy/apps/<name>/<repo>
updateSourceDir = (apps, callback) =>
    if apps.length > 0
        name = apps.pop()
        if checkOldSource(name)
            repo = getRepo(name)
            # Move old source
            if repo is name
                source = path.join(pathRoot, name, repo)
                move source, path.join(pathRoot, name, "cozy-#{repo}"), (err) =>
                    console.log err
                    if err?
                        callback(err)
                    else
                        dest = path.join(pathRoot, name, repo)
                        source = path.join(pathRoot, name, "cozy-#{name}", repo)
                        move source, dest, (err) =>
                            console.log err
                            if err?
                                callback err
                            else
                                rm "/usr/local/cozy/apps/#{name}/cozy-#{name}", (err) =>
                                    console.log err
                                    if err?
                                        callback err
                                    else
                                        updateSourceDir apps, callback


            else
                dest = path.join(pathRoot, name, repo)
                source = path.join(pathRoot, name, name, repo)
                move source, dest, (err) =>
                    if err?
                        callback err
                    else   
                        # Remove old directory
                        rm path.join(pathRoot, name, name), (err) =>
                            if err?
                                callback err
                            else
                                updateSourceDir apps, callback
        else
            console.log "#{name} : Already moved"
            updateSourceDir apps, callback
    else
        callback()

# Create stack.json with file stored in autostart of old controller
createStackFile = (callback) =>
    autostartPath = "/usr/local/cozy/autostart"
    if fs.existsSync autostartPath
        stackFile = "/usr/local/cozy/apps/stack.json"
        fs.open stackFile,'w', (err) =>
            files = fs.readdirSync '/usr/local/cozy/autostart/'
            stack = {}
            for file in files
                if file.indexOf('home') isnt -1
                    stack.home = JSON.parse(fs.readFileSync path.join(autostartPath, file), 'utf8')
                else if file.indexOf('proxy') isnt -1
                    stack.proxy = JSON.parse(fs.readFileSync path.join(autostartPath, file), 'utf8')
                else if file.indexOf('data-system') isnt -1
                    stack['data-system'] = JSON.parse(fs.readFileSync path.join(autostartPath, file), 'utf8')
            fs.writeFile stackFile, JSON.stringify(stack), callback
    else
        callback()


#update Files -> usefull for patch
module.exports.apply = (callback) =>
    console.log "APPLY patch ..."
    # Update source path
    if fs.existsSync '/etc/cozy/controller.token'
        fs.unlinkSync '/etc/cozy/controller.token'
    dirs = fs.readdirSync('/usr/local/cozy/apps')
    console.log "Move old source directory ..."
    updateSourceDir dirs, (err) =>
        if err?
            console.log err
            callback err
        else
            console.log "Create Stack File ..."
            createStackFile (err) =>
                if err?
                    callback err
                else
                    fs.open '/etc/cozy/.patch', 'w', callback