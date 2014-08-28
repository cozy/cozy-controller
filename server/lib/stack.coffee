fs = require 'fs'
config = require('./conf').get

module.exports.addApp = (app, callback) =>
    console.log "add App"
    console.log config('file_sack')
    fs.readFile config('file_stack'), 'utf8', (err, data) =>
        try
            data = JSON.parse(data) 
        catch
            data = {}
        data[app.name] = app
        fs.open config('file_stack'), 'w', (err, fd) =>
            fs.write fd, JSON.stringify(data), 0, data.length, 0, callback


module.exports.removeApp = (name, callback) =>
    fs.readFile config('file_stack'), 'utf8', (err, data) =>
        try
            data = JSON.parse(data) 
        catch
            data = {}
        delete data[name]
        fs.open config('file_stack'), 'w', (err, fd) =>
            fs.write fd, JSON.stringify(data), 0, data.length, 0, callback