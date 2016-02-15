# This test will be useful when user could change controller configuration.
# This feature is not available for the moment.

helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json-light').JsonClient
config = require('../server/lib/conf').get
client = ""
configurationFile = "/etc/cozy/controller.json"
spawn = require('child_process').spawn


describe "Configuration", ->

    before helpers.cleanApp
    after (done)->
        helpers.cleanApp () ->
            conf = {}
            fs.writeFileSync configurationFile, JSON.stringify(conf)
            done()


    describe "Option BIND_IP_PROXY", ->

        describe 'Bind proxy on 127.0.0.1', ->
            it "When I started server with BIND_IP_PROXY", (done) ->
                process.env.BIND_IP_PROXY = '127.0.0.1'
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "Then I install proxy", (done) ->
                @timeout 500000
                app =
                    name: "proxy"
                    repository:
                        url: "https://github.com/cozy/cozy-proxy.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/proxy/install', "start":app, (err, res, body) =>
                    done()

            it "And proxy listen on 127.0.0.1", (done) ->
                lsof = spawn 'lsof', ['-i', '-s', 'TCP:listen']
                lsof.stdout.on 'data', (data)->
                    tab = data.toString().split('\n')
                    for proc in tab
                        if proc.indexOf('cozy-proxy') isnt -1
                            proc.should.contain 'localhost:9104'

                lsof.on 'close', (code) ->
                    done()

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done

        describe 'Bind proxy on default ip (0.0.0.0)', ->

            it "When I started server with BIND_IP_PROXY", (done) ->
                delete process.env.BIND_IP_PROXY
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "Then I install proxy", (done) ->
                @timeout 500000
                app =
                    name: "proxy"
                    repository:
                        url: "https://github.com/cozy/cozy-proxy.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/proxy/install', "start":app, (err, res, body) =>
                    done()

            it "And proxy listen on 0.0.0.0", (done) ->
                lsof = spawn 'lsof', ['-i', '-s', 'TCP:listen']
                lsof.stdout.on 'data', (data)->
                    tab = data.toString().split('\n')
                    for proc in tab
                        if proc.indexOf('cozy-proxy') isnt -1
                            proc.should.contain '*:9104'
                lsof.on 'close', (code) ->
                    done()

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done

    describe "Stack.json", ->

        describe "Configuration of stack.json (default)", ->

            it "I started server", (done) ->
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
                    console.log err if err
                    @res = res
                    @port = body.drone.port
                    dsPort = @port
                    done()

            it "Then stack file should contains data-system information", ->
                data = fs.readFileSync "/usr/local/cozy/apps/stack.json", 'utf8'
                data = JSON.parse(data)
                should.exist data['data-system']

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done


        describe "New configuration of stack.json", ->

            it "When I change configuration file", ->
                conf = "file_stack": "/usr/local/cozy/stack.json"
                fs.writeFileSync configurationFile, JSON.stringify(conf)
                fs.renameSync '/usr/local/cozy/apps/stack.json', '/usr/local/cozy/stack.json'

            it "And I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "And data-system should be started", (done) ->
                @timeout 500000
                client.get 'drones/running', (err, res, body) =>
                    console.log err if err
                    isRunning  = 'data-system' in Object.keys(body.app)
                    isRunning.should.equal true
                    done()


            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done

    describe "Log directory", ->

        describe "Configuration of log directory (default)", ->

            it "I started server", (done) ->
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
                client.post 'apps/data-system/uninstall', "name":"data-system", (err, res, body) =>
                    client.post 'apps/data-system/install', "start":app, (err, res, body) =>
                        @res = res
                        @port = body.drone.port
                        dsPort = @port
                        done()

            it "Then data-system logs should be stored in log directory", ->
                log = fs.existsSync "/usr/local/var/log/cozy/data-system.log"
                log.should.equal true

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done


        describe "New configuration of log directory", ->

            it "When I change log directory", ->
                conf =
                    "dir_app_log": "/usr/local/cozy"
                fs.writeFileSync configurationFile, JSON.stringify(conf)
                fs.renameSync '/usr/local/cozy/stack.json', '/usr/local/cozy/apps/stack.json'

            it "And I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "Then data-system logs should be stored in log directory", ->
                log = fs.existsSync "/usr/local/cozy/data-system.log"
                log.should.equal true

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done

    describe "Stack.token", ->

        describe "Configuration of stack.token (default)", ->

            it "I started server", (done) ->
                @timeout 100000
                helpers.startApp () =>
                    client = helpers.getClient()
                    done()

            it "Then stack file should contains data-system information", ->
                log = fs.existsSync "/etc/cozy/stack.token"
                log.should.equal true
                data = fs.readFileSync "/etc/cozy/stack.token"
                data.length.should.equal 32

            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done


        describe "New configuration of stack.token", ->

            it "When I initialize configuration for token file", ->
                if not fs.existsSync "/etc/cozy/test"
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
                log = fs.existsSync "/etc/cozy/test/stack.token"
                log.should.equal true
                data = fs.readFileSync "/etc/cozy/test/stack.token"
                data.length.should.equal 32


            it "And I stopped server", (done) ->
                @timeout 10000
                helpers.stopApp done

            it "And I remove old stack.token", ->
                fs.unlinkSync "/etc/cozy/test/stack.token"
