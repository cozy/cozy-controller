# This test will be usefull when user could change controller configuration.

###helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json-light').JsonClient
config = require('../server/lib/conf').get
client = ""
configurationFile = "/etc/cozy/controller.json"


describe "Configuration", ->

    before helpers.cleanApp
    after helpers.cleanApp

    describe "Stack.json", ->

        describe "Configuration of stack.json", ->
            after (done) =>
                @timeout 10000
                helpers.stopApp done

            it "When I initialize configuration file", ->
                conf =
                    "file_stack": "/usr/local/cozy/stack.json"
                fs.writeFileSync configurationFile, JSON.stringify(conf)

            it "And I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "And I install data-system", (done) ->
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
                    @port = body.drone.port
                    dsPort = @port
                    done()

            it "Then stack file should contains data-system information", ->
                data = fs.readFileSync "/usr/local/cozy/stack.json", 'utf8'
                data = JSON.parse(data)
                should.exist data['data-system']


        describe "New configuration of stack.json", ->
            after (done) =>
                @timeout 10000
                helpers.stopApp done

            it "When I change configuration file", ->
                conf =
                    "old":
                        "file_stack": "/usr/local/cozy/stack.json"
                fs.writeFileSync configurationFile, JSON.stringify(conf)

            it "And I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "Then stack file should contains data-system information", ->
                data = fs.readFileSync "/usr/local/cozy/apps/stack.json", 'utf8'
                data = JSON.parse(data)
                should.exist data['data-system']

    describe "Log directory", ->

        describe "Configuration of log directory", ->

            it "When I initialize log directory", ->
                conf =
                    "dir_log": "/usr/local/cozy"
                fs.writeFileSync configurationFile, JSON.stringify(conf)

            it "And I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "And I install data-system", (done) ->
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
                    @port = body.drone.port
                    dsPort = @port
                    done()

            it "Then data-system logs should be stored in log directory", ->
                log = fs.existSync "/usr/local/cozy/data-system.log"
                log.should.be true

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done


        describe "New configuration of stack.token", ->

            it "When I change log directory", ->
                conf =
                    "old_dir_log": "/usr/local/cozy"
                fs.writeFileSync configurationFile, JSON.stringify(conf)

            it "And I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "Then stack file should contains data-system information", ->
                log = fs.existSync "/usr/local/cozy/data-system.log"
                log.should.be true

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done

    describe "Stack.token", ->

        describe "Configuration of stack.token", ->

            it "When I initialize token file", ->
                if not fs.existSync "/etc/cozy/test"
                    fs.mkdirSync "/etc/cozy/test"
                conf =
                    "file_token": "/etc/cozy/test/stack.token"
                fs.writeFileSync configurationFile, JSON.stringify(conf)

            it "And I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "Then stack token should be stored in token file", ->
                log = fs.existSync "/etc/cozy/test/stack.token"
                log.should.be true
                data = fs.readFileSync "/etc/cozy/test/stack.token"
                data.length.should.be 32


            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done


        describe "New configuration of stack.token", ->

            it "When I change token file", ->
                conf = {}
                fs.writeFileSync configurationFile, JSON.stringify(conf)

            it "And I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "Then stack file should contains data-system information", ->
                log = fs.existSync "/etc/cozy/stack.token"
                log.should.be true
                data = fs.readFileSync "/etc/cozy/stack.token"
                data.length.should.be 32

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done

            it "And I remove old stack.token", (done) ->
                fs.unlinkSync "/etc/cozy/test/stack.token"###