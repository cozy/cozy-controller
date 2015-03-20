fs = require 'fs'
exec = require('child_process').exec

###
    Return disk space information
###
module.exports.info = (req, res, next) ->
    freeMemCmd =
        "free | grep cache: | cut -d':' -f2 | sed -e 's/^ *[0-9]* *//'";
    extractValFromDfValue = (val) ->
        unit = val[val.length - 1]
        val = val.substring(0, val.length - 1)
        val = val.replace(',', '.')
        if unit is 'M'
            val = "" + (parseFloat(val) / 1000)
        if unit is 'T'
            val = "" + (parseFloat(val) * 1000)
        return val

    # Extract disk information from couchDB stored in dir and response <resp>
    # of command df -H
    extractDataFromDfResult =  (dir, resp) ->
        data = {}
        lines = resp.split('\n')
        currentMountPoint = ''
        for line in lines
            line = line.replace /[\s]+/g, ' '
            lineData = line.split(' ')
            if lineData.length > 5 and lineData[5] is '/'
                freeSpace = lineData[3].substring(0, lineData[3].length - 1)
                totalSpace = lineData[1].substring(0, lineData[1].length - 1)
                usedSpace = lineData[2].substring(0, lineData[2].length - 1)
                unit = lineData[1].slice(-1)
                data.totalDiskSpace = totalSpace
                data.freeDiskSpace = freeSpace
                data.usedDiskSpace = usedSpace
                data.unit = unit
        return data

    getCouchStoragePlace = (callback) ->
        couchConfigFile = "/usr/local/etc/couchdb/local.ini"
        databaseDirLine = "database_dir"
        fs.readFile couchConfigFile, (err, data) ->
            dir = '/'
            if not err?
                lines = data.toString().split('\n')
                for line in lines
                    if line.indexOf(databaseDirLine) is 0
                        dir = line.split('=')[1]
                callback null, dir.trim()
            else
                callback err

    getCouchStoragePlace (err, dir) ->
        exec 'df -h', (err, resp) ->
            if err
                res.send 500, err
            else
                res.send 200, extractDataFromDfResult(dir, resp)
