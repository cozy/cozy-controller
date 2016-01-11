helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json-light').JsonClient
config = require('../server/lib/conf').get
controller = require '../server/lib/controller'
token = require '../server/middlewares/token'
exec = require('child_process').exec
homePort = ""
dsPort = ""


describe "Autostart", ->

    describe "Controller installation", ->
        server = ""
        client = ""
        before helpers.cleanApp

        before (done) ->
            @timeout 100000
            helpers.startApp (appli) =>
                server = appli
                client = helpers.getClient()
                done()

        after (done) ->
            @timeout 20000
            helpers.stopApp done

        describe "Install data-system", ->

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
                    @port = body.drone.port
                    dsPort = @port
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And data-system is started", (done) ->
                clientDS = new Client "http://localhost:#{@port}"
                clientDS.get '/', (err, res) ->
                    res.statusCode.should.equal 200
                    done()

        describe "Install home", ->

            it "When I install home", (done) ->
                @timeout 500000
                app =
                    name: "home"
                    repository:
                        url: "https://github.com/poupotte/test-controller.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/home/install', "start":app, (err, res, body) =>
                    @res = res
                    @port = body.drone.port
                    homePort = @port
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And home is started", (done) ->
                clientDS = new Client "http://localhost:#{@port}"
                clientDS.get '/', (err, res) ->
                    res.statusCode.should.equal 200
                    done()

        describe "Install proxy", ->

            it "When I install proxy", (done) ->
                @timeout 500000
                app =
                    name: "proxy"
                    repository:
                        url: "https://github.com/poupotte/test-controller.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/proxy/install', "start":app, (err, res, body) =>
                    @res = res
                    @port = body.drone.port
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And proxy is started", (done) ->
                clientProxy = new Client "http://localhost:#{@port}"
                clientProxy.get '/', (err, res) ->
                    status = res.statusCode in [200, 302]
                    status.should.equal true
                    done()

        ###describe "Install todos", ->

            it "When I install todos", (done) ->
                @timeout 500000
                homeClient = new Client "http://localhost:#{homePort}"
                app =
                    "domain": "localhost"
                    "repository":
                        "type": "git"
                    "scripts":
                        "start": "server.coffee"
                    "name": "todos"
                    "displayName":  "todos"
                    "user": 'todos'
                    "git": "https://github.com/cozy/cozy-todos.git"
                homeClient.post "api/applications/install", app, (err, res, body) =>
                    @res = res
                    # Don't know why : should restart else there is a token pb
                    homeClient.post "api/applications/install", app, (err, res, body) ->
                        done()

            it "Then statusCode should be 201", ->
                console.log @res.statusCode
                @res.statusCode.should.equal 201

            it "And todos is started", (done) ->
                clientTodos = new Client "http://localhost:#{@port}"
                clientTodos.get '/', (err, res) ->
                    res.statusCode.should.equal 200
                    done()

            it 'And I change port in database', (done) ->
                dsClient = new Client "http://localhost:#{dsPort}"
                stackToken = token.get()
                dsClient.setBasicAuth 'home', stackToken
                dsClient.post 'request/application/all/', {}, (err, res, body) ->
                    for app in body
                        appli = app.value
                        if appli.name is 'todos'
                            appli.port = 1111
                            appli.state = 'installed'
                            appli.password = 'test'
                            dsClient.put "data/#{appli._id}/", appli, (err, res, body) ->
                                console.log err
                                console.log body
                                done() ###

    describe "Restart controller", ->
        server = ""
        client = ""

        before (done) ->
            @timeout 100000
            helpers.startApp () =>
                client = helpers.getClient()
                done()
        after (done) ->
            @timeout 20000
            helpers.stopApp done

        it "Then all applications shoulb be started", (done) ->
            @timeout 10000
            client.get 'drones/running', (err, res, body) =>
                should.exist body.app
                should.exist body.app['data-system']
                should.exist body.app.proxy
                should.exist body.app.home
                #should.exist body.app.todos
                done()

        ###it "And todos has new port", (done) ->
            dsClient = new Client "http://localhost:#{dsPort}"
            stackToken = token.get()
            dsClient.setBasicAuth 'home', stackToken
            dsClient.post 'request/application/all/', {}, (err, res, body) ->
                for app in body
                    appli = app.value
                    if appli.name is 'todos'
                        appli.port.should.not.equal 1111
                        done()###

    describe "Restart controller without couchDB server", ->
        server = ""
        client = ""

        before (done) ->
            @timeout 100000
            helpers.stopCouchDB ->
                helpers.startApp ->
                    client = helpers.getClient()
                    done()

        after (done) ->
            helpers.startCouchDB done

        it "Then controller server doesn't start", (done) ->
            @timeout 10000
            client.get 'drones/running', (err, res, body) ->
                should.not.exist res
                done()
