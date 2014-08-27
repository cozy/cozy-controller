helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json').JsonClient
config = require('../server/lib/conf').get
client = ""
dsPort = ""
server = ""


describe "Spawner", ->

    before helpers.cleanApp 
    before (done) =>
        @timeout 100000
        helpers.startApp (appli) =>
            server = appli
            client = helpers.getClient()
            done()
    after (done) =>
        @timeout 10000
        helpers.stopApp server, done

    describe "Installation", ->

        describe "Installation with bad argument", ->

            it "When I try to install application", (done) ->
                app = 
                    name: "data-system"
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/install', app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400


            it "Then body.error should be 'Manifest should be declared in body.start'", ->
                should.exist @body.error
                @body.error.should.equal 'Manifest should be declared in body.start'

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
                    @port = body.drone.port
                    dsPort = @port
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And stack.token has been created", ->
                fs.existsSync(config('file_token')).should.be.ok

            it "And data-system has been added in stack.json", ->
                fs.existsSync('/usr/local/cozy/apps/stack.json').should.be.ok
                stack = fs.readFileSync('/usr/local/cozy/apps/stack.json', 'utf8')
                exist = stack.indexOf 'data-system'
                exist.should.not.equal -1

            it "And file log has been created (/var/log/cozy/data-system.log)", ->
                fs.existsSync('/var/log/cozy/data-system.log').should.be.ok

            it "And data-system source should be imported (in /usr/local/cozy/apps/data-system/cozy-data-system", ->
                fs.existsSync('/usr/local/cozy/apps/data-system').should.be.ok
                fs.existsSync('/usr/local/cozy/apps/data-system/cozy-data-system').should.be.ok
                fs.existsSync('/usr/local/cozy/apps/data-system/cozy-data-system/package.json').should.be.ok

            it "And data-system is started", (done) ->
                clientDS = new Client "http://localhost:#{@port}"
                clientDS.get '/', (err, res) ->
                    res.statusCode.should.equal 200
                    done()

    describe "Stop application", ->

        describe "Stop application with bad argument", ->

            it "When I try to stop application", (done) ->
                @timeout 100000
                app = 
                    name: "data-system"
                client.post 'apps/data-system/stop', app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400

            it "Then body.error should be 'Application name should be declared in body.stop.name'", ->
                should.exist @body.error
                @body.error.should.equal 'Application name should be declared in body.stop.name'

        describe "Stop data-system", ->

            it "When I stop data-system", (done) ->
                @timeout 100000
                app = 
                    name: "data-system"
                client.post 'apps/data-system/stop', "stop":app, (err, res, body) =>
                    @res = res
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And data-system should be stopped", (done) ->
                clientDS = new Client "http://localhost:#{dsPort}"
                clientDS.get '/', (err, res) ->
                    should.not.exist res
                    done()


    describe "Restart application", ->

        describe "Restart application with bad argument", ->

            it "When I restart data-system", (done) ->
                @timeout 100000
                app = 
                    name: "data-system"
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/start', app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400

            it "Then body.error should be 'Manifest should be declared in body.start'", ->
                should.exist @body.error
                @body.error.should.equal 'Manifest should be declared in body.start'

        describe "Restart data-system", ->

            it "When I restart data-system", (done) ->
                @timeout 100000
                app = 
                    name: "data-system"
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/start', "start":app, (err, res, body) =>
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

    describe "Uninstall application", ->

        describe "Unisntall application with bad argument", ->

            it "When I try to uninstall application", (done) ->
                @timeout 100000
                app = 
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/uninstall', app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400

            it "Then body.error should be 'Application name should be declared in body.name'", ->
                should.exist @body.error
                @body.error.should.equal 'Application name should be declared in body.name'


        describe "Uninstall data-system", ->

            it "When I uninstall data-system", (done) ->
                @timeout 100000
                app = 
                    name: "data-system"
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/uninstall', app, (err, res, body) =>
                    @res = res
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And data-system should be stopped", (done) ->
                clientDS = new Client "http://localhost:#{dsPort}"
                clientDS.get '/', (err, res) ->
                    should.not.exist res
                    done()

            it "And logs file should be removed", ->
                fs.existsSync('/var/log/cozy/data-system.log').should.not.be.ok

            it "And data-system repo should be removed", ->
                fs.existsSync('/usr/local/cozy/apps/data-system').should.not.be.ok

            it "And data-system has been removed from stack.json", ->
                fs.existsSync('/usr/local/cozy/apps/stack.json').should.be.ok
                stack = fs.readFileSync('/usr/local/cozy/apps/stack.json', 'utf8')
                exist = stack.indexOf 'data-system'
                exist.should.equal -1