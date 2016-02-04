helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json-light').JsonClient
config = require('../server/lib/conf').get


describe "App Stopped", ->
    describe "Application should stopped if server has stopped", ->
        client = ""
        dsPort = ""
        port = 0

        describe "Install data-system", ->

            before helpers.cleanApp
            before (done) ->
                @timeout 100000
                helpers.startApp ->
                    client = helpers.getClient()
                    done()

            after (done) ->
                @timeout 20000
                helpers.stopApp ->
                    done()

            it "When I install data-system", (done) ->
                @timeout 500000
                app =
                    name: "data-system"
                    repository:
                        url: "https://github.com/poupotte/test-controller.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/install', "start":app, (err, res, body) =>
                    @res = res
                    port = body.drone.port
                    dsPort = port
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And data-system is started", (done) ->
                clientDS = new Client "http://localhost:#{port}"
                clientDS.get '/', (err, res) ->
                    res.statusCode.should.equal 200
                    done()

        describe "Stop server", ->

            it "Then data-system is stopped", (done)->
                @timeout 30000
                setTimeout ->
                    clientDS = new Client "http://localhost:#{port}"
                    clientDS.get '/', (err, res) ->
                        should.not.exist res
                        done()
                , 20000
