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
            if lineData.length > 5
                mountPoint = lineData[5]
                if (dir.indexOf(mountPoint) is 0 and
                        currentMountPoint.length < mountPoint.length and
                        mountPoint.length <= dir.length and
                        mountPoint[0] is '/')
                    currentMountPoint = mountPoint
                    data.freeDiskSpace = extractValFromDfValue lineData[3]
                    data.usedDiskSpace = extractValFromDfValue lineData[2]
                    data.totalDiskSpace = extractValFromDfValue lineData[1]
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