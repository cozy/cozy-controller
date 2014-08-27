helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
server = ""
client = ""


describe "Disk info", ->

    before helpers.cleanApp 
    before (done) =>
        @timeout 100000
        helpers.startApp (appli) =>
            server = appli
            client = helpers.getClient()
            done()
    after (done) =>
        @timeout 20000
        helpers.stopApp server, done

    it "When I get disk info", (done) ->
        client.get 'diskinfo', (err, res, body) =>
            @res = res
            @body = body
            done()

    it "Then statusCode should be 200", ->
        @res.statusCode.should.equal 200

    it "And body should be have freeDiskSpace attribute", ->
        should.exist @body.freeDiskSpace

    it "And body should be have totalDiskSpace attribute", ->
        should.exist @body.totalDiskSpace

    it "And body should be have usedDiskSpace attribute", ->
        should.exist @body.usedDiskSpace

