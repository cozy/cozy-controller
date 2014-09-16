helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json').JsonClient
config = require('../server/lib/conf').get
client = ""
dsPort = ""
server = ""


describe "App Stopped", ->
    server = {}

    before helpers.cleanApp 
    before (done) =>
        @timeout 100000
        helpers.startApp (appli) =>
            server = appli
            client = helpers.getClient()
            done()

    describe "Application should stopped if server has stopped", ->
        port = 0

        describe "Install data-system", =>

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

        describe "Stop server", =>

            it "When I stop server", (done) ->
                @timeout 10000
                #console.log server
                helpers.stopApp server, () =>
                    client.get 'drones', (err, res) =>
                        console.log err
                        console.log res
                        done()

            it "And data-system is stopped", (done)->
                @timeout 30000
                setTimeout () =>
                    console.log port
                    clientDS = new Client "http://localhost:#{port}"
                    clientDS.get '/', (err, res) ->
                        should.not.exist res
                        done()
                , 20000