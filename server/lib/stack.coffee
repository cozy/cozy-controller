fs = require 'fs'
config = require('./conf').get

###
    Add application <app> in stack.json
        * read stack file
        * parse date (in json)
        * add application <app>
        * write stack file with new stack applications
###
module.exports.addApp = (app, callback) =>
    fs.readFile config('file_stack'), 'utf8', (err, data) =>
        try
            data = JSON.parse(data) 
        catch
            data = {}
        data[app.name] = app
        fs.open config('file_stack'), 'w', (err, fd) =>
            fs.write fd, JSON.stringify(data), 0, data.length, 0, callback

###
    Remove application <name> from stack.json
        * read stack file
        * parse date (in json)
        * remove application <name>
        * write stack file with new stack applications
###
module.exports.removeApp = (name, callback) =>
    fs.readFile config('file_stack'), 'utf8', (err, data) =>
        try
            data = JSON.parse(data) 
        catch
            data = {}
        delete data[name]
        fs.open config('file_stack'), 'w', (err, fd) =>
            fs.write fd, JSON.stringify(data), 0, data.length, 0, callback