helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json-light').JsonClient
config = require('../server/lib/conf').get
client = ""
dsPort = ""


describe "Spawner", ->

    before helpers.cleanApp
    before (done) ->
        @timeout 100000
        helpers.startApp () =>
            client = helpers.getClient()
            require('../server/lib/conf').init ->
                done()

    after (done) ->
        @timeout 10000
        helpers.stopApp done

    describe "Installation", ->

        describe "Installation with bad argument", ->

            it "When I try to install application", (done) ->
                app =
                    name: "data-system"
                    repository:
                        url: "https://github.com/poupotte/test-controller.git"
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
                @body.message.should.equal 'Manifest should be declared in body.start'

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

            it "And stack.token has been created", ->
                fs.existsSync(config('file_token')).should.be.ok

            it "And data-system has been added in stack.json", ->
                fs.existsSync(config('file_stack')).should.be.ok
                stack = fs.readFileSync(config('file_stack'), 'utf8')
                exist = stack.indexOf 'data-system'
                exist.should.not.equal -1

            it "And file log has been created (/usr/local/var/log/cozy/data-system.log)", ->
                fs.existsSync('/usr/local/var/log/cozy/data-system.log').should.be.ok

            it "And data-system source should be imported (in /usr/local/cozy/apps/data-system", ->
                fs.existsSync("#{config('dir_source')}/data-system").should.be.ok
                fs.existsSync("#{config('dir_source')}/data-system/package.json").should.be.ok

            it "And data-system is started", (done) ->
                clientDS = new Client "http://localhost:#{@port}/"
                clientDS.get '/', (err, res) ->
                    res.statusCode.should.equal 200
                    done()

    describe "Stop application", ->

        describe "Stop application which isn't installed", ->

            it "When I try to stop application", (done) ->
                @timeout 100000
                app =
                    name: "data-systel"
                client.post 'apps/data-systel/stop', stop: app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400

            it "Then body.error should be 'Error: Cannot stop an application not started'", ->
                @body.message.should.equal 'Error: Cannot stop an application not started'

        describe "Stop data-system", ->

            it "When I stop data-system", (done) ->
                @timeout 100000
                app =
                    name: "data-system"
                client.post 'apps/data-system/stop', stop:app, (err, res, body) =>
                    @res = res
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And data-system should be stopped", (done) ->
                clientDS = new Client "http://localhost:#{dsPort}"
                clientDS.get '/', (err, res) ->
                    done()


    describe "Restart application", ->

        describe "Restart application with bad argument", ->

            it "When I restart data-system", (done) ->
                @timeout 100000
                app =
                    name: "data-system"
                    repository:
                        url: "https://github.com/poupotte/test-controller.git"
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
                @body.message.should.equal 'Manifest should be declared in body.start'

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

    describe "Update application", ->

        describe "Update application with not installed", ->

            it "When I restart data-system", (done) ->
                @timeout 100000
                app =
                    name: "data-systel"
                    repository:
                        url: "https://github.com/cozy/cozy-data-systel.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-systel/update', update: app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400

            it "Then body.error should be 'Error: Application is not installed'", ->
                @body.message.should.equal 'Error: Application is not installed'

        describe "Update data-system", ->

            it "When I update data-system", (done) ->
                @timeout 100000
                app =
                    name: "data-system"
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-system/update', update: app, (err, res, body) =>
                    @res = res
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And data-system is started", (done) ->
                clientDS = new Client "http://localhost:#{dsPort}"
                clientDS.get '/', (err, res) ->
                    res.statusCode.should.equal 200
                    done()

    describe "Recover all started application", ->

        it "When I send request to recover all started applications", (done) ->
            client.get 'drones/running', (err, res, body) =>
                @res = res
                @body = body
                done()

        it "Then statusCode should be 200", ->
            @res.statusCode.should.equal 200

        it "And data-system is in list", ->
            should.exist @body.app
            should.exist @body.app['data-system']

    describe "Recover all application", ->

        it "When I send request to recover all applications", (done) ->
            client.get 'apps/all', (err, res, body) =>
                @res = res
                @body = body
                done()

        it "Then statusCode should be 200", ->
            @res.statusCode.should.equal 200

        it "And data-system is in list", ->
            should.exist @body.app
            should.exist @body.app['data-system']

    describe "Uninstall application", ->

        describe "Unisntall application not installed", ->

            it "When I try to uninstall application", (done) ->
                @timeout 100000
                app =
                    repository:
                        url: "https://github.com/cozy/cozy-data-system.git"
                        type: "git"
                    scripts:
                        start: "server.coffee"
                client.post 'apps/data-systel/uninstall', app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400

            it "And body.error should be 'Error: Cannot uninstall an application not installed'", ->
                string = 'Error: Cannot uninstall an application not installed'
                @body.message.should.equal string


        describe "Uninstall data-system", ->

            it "When I uninstall data-system", (done) ->
                @timeout 100000
                app =
                    name: "data-system"
                    repository:
                        url: "https://github.com/poupotte/test-controller.git"
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
                    setTimeout () ->
                        done()
                    , 1000

            it "And logs file should be removed", ->
                fs.existsSync('/var/log/cozy/data-system.log').should.not.be.ok

            it "And data-system repo should be removed", ->
                fs.existsSync('/usr/local/cozy/apps/data-system').should.not.be.ok

            it "And data-system has been removed from stack.json", ->
                fs.existsSync(config('file_stack')).should.be.ok
                stack = fs.readFileSync(config('file_stack'), 'utf8')
                exist = stack.indexOf 'data-system'
                exist.should.equal -1