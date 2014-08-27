fs = require 'fs'

module.exports.addApp = (app, callback) =>
    fs.readFile '/usr/local/cozy/apps/stack.json', 'utf8', (err, data) =>
        try
            data = JSON.parse(data) 
        catch
            data = {}
        data[app.name] = app
        fs.open '/usr/local/cozy/apps/stack.json', 'w', (err, fd) =>
            fs.write fd, JSON.stringify(data), 0, data.length, 0, callback


module.exports.removeApp = (name, callback) =>