fs = require 'fs'
exec = require('child_process').exec

log = require('printit')
    date: true
    prefix: 'cozy-controller'


# Looks for entry database_dir in the given couchdb config file.
# It returns the value of the entry.
getCouchStoragePlaceFromFile = (file, callback) ->
    databaseDirLine = "database_dir"
    fs.readFile file, (err, data) ->
        dir = '/'
        if not err?
            lines = data.toString().split('\n')
            for line in lines
                if line.indexOf(databaseDirLine) is 0
                    dir = line.split('=')[1]

            callback null, dir.trim()
        else
            callback err


# Looks for common couchdb configuration file location. When the file is found,
# it looks for the database_dir entry to find the couchdb storage location.
# The location of the configuration file can be given as environment variable.
getCouchStoragePlace = (callback) ->
    files = [
        "/usr/local/etc/couchdb/local.ini"
        "/etc/couchdb/local.ini"
        "/usr/local/etc/couchdb/default.ini"
        "/etc/couchdb/default.ini"
    ]
    if process.env.COUCH_LOCAL_CONFIG
        files.unshift process.env.COUCH_LOCAL_CONFIG

    do getDir = ->
        if files.length is 0
            callback null, '/'
        else
            file = files.shift()
            log.info "Looks for storage info in config file: #{file}"
            getCouchStoragePlaceFromFile file, (err, dir) ->
                if err
                    log.info 'File not found.'
                    getDir()
                else if dir is '/'
                    log.info 'No storage location found.'
                    getDir()
                else
                    callback null, dir


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
    # It checks if it it finds the given dir mounting point by comparing the
    # mounting point with the beginning of the given dir. If it finds it
    # it returns the result for this mounting point. If it doesn't find it,
    # it returns the result dir.
    extractDataFromDfResult =  (dir, resp) ->
        data = null
        defaultData = {}
        lines = resp.split '\n'
        currentMountPoint = ''

        for line in lines
            line = line.replace /[\s]+/g, ' '
            lineData = line.split(' ')
            if lineData.length > 5 and (lineData[5] is '/' or (dir.indexOf(lineData[5]) isnt -1) or (lineData[5].indexOf(dir) isnt -1))
                totalSpace = lineData[1].substring(0, lineData[1].length - 1)
                usedSpace = lineData[2].substring(0, lineData[2].length - 1)
                freeSpace = lineData[3].substring(0, lineData[3].length - 1)
                totalUnit = lineData[1].slice(-1)
                usedUnit = lineData[2].slice(-1)
                freeUnit = lineData[3].slice(-1)

                if lineData[5] is '/'
                    defaultData.totalDiskSpace = totalSpace
                    defaultData.freeDiskSpace = freeSpace
                    defaultData.usedDiskSpace = usedSpace
                    defaultData.totalUnit = totalUnit
                    defaultData.usedUnit = usedUnit
                    defaultData.freeUnit = freeUnit
                    defaultData.dir = '/usr/local/var/lib/couchdb'
                    defaultData.mount = '/'

                else if ((dir.indexOf(lineData[5]) is 0) or (lineData[5].indexOf(dir) is 0))
                    data = {}
                    data.totalDiskSpace = totalSpace
                    data.freeDiskSpace = freeSpace
                    data.usedDiskSpace = usedSpace
                    data.totalUnit = totalUnit
                    data.usedUnit = usedUnit
                    data.freeUnit = freeUnit
                    data.dir = dir
                    data.mount = lineData[5]

        return data or defaultData

    getCouchStoragePlace (err, dir) ->
        exec "df -h #{dir}", (err, resp) ->
            if err
                res.send 500, err
            else
                data = extractDataFromDfResult dir, resp
                log.info "Disk usage information: #{JSON.stringify(data)}"
                res.send 200, data
