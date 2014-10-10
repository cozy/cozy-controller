helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json-light').JsonClient
config = require('../server/lib/conf').get
client = ""


describe "App Stopped", ->
    describe "Application should stopped if server has stopped", ->
        port = 0

        before helpers.cleanApp
        before (done) ->
            @timeout 100000
            helpers.startApp () =>
                client = helpers.getClient()
                done()

        after (done) ->
            @timeout 20000
            helpers.stopApp () ->
                done()

        describe "Install data-system", ->

            it "When I install data-system", (done) ->
                @timeout 500000
                app =
                    name: "data-system"
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
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

        describe "Try to install an other 'data-system'", ->

            it "When I install data-system", (done) ->
                @timeout 500000
                app =
                    name: "data-system"
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/install', "start":app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400

            it "And body.error should be 'Application already exists'", ->
                @body.error.should.equal 'Application already exists'

        describe "Try to start an other 'data-system'", ->

            it "When I install data-system", (done) ->
                @timeout 500000
                app =
                    name: "data-system"
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/start', "start":app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400

            it "And body.error should be 'Application already exists'", ->
                @body.error.should.equal 'Application already exists'