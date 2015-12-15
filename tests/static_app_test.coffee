helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
Client = require('request-json-light').JsonClient
config = require('../server/lib/conf').get
client = ""
dsPort = ""


describe "Install static app", ->

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
                    name: "front"
                    repository:
                        url: "https://github.com/lemelon/cozy-front.git"
                        type: "git"
                    type: "static"
                client.post 'apps/front/install', app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400


            it "Then body.error should be 'Manifest should be declared in body.start'", ->
                @body.message.should.equal 'Manifest should be declared in body.start'

        describe "Installation with bad git url", ->

            it "When I try to install application", (done) ->
                app =
                    name: "front"
                    repository:
                        url: "https://github.com/lemelon/cozy-front"
                        type: "git"
                    type: "static"
                client.post 'apps/front/install', app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 400", ->
                @res.statusCode.should.equal 400


            it "Then body.error should be 'Manifest should be declared in body.start'", ->
                @body.message.should.equal 'Manifest should be declared in body.start'

        describe "Install static app", ->

            it "When I install static app", (done) ->
                @timeout 500000
                app =
                    name: "front"
                    repository:
                        url: "https://github.com/lemelon/cozy-front.git"
                        type: "git"
                    type: "static"
                client.post 'apps/front/install', "start":app, (err, res, body) =>
                    @res = res
                    console.log body.drone
                    @type = body.drone.type
                    dsPort = @port
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And stack.token has been created", ->
                fs.existsSync(config('file_token')).should.be.ok

            it "And front should not be added in stack.json", ->
                fs.existsSync(config('file_stack')).should.be.ok
                stack = fs.readFileSync(config('file_stack'), 'utf8')
                exist = stack.indexOf 'front'
                exist.should.equal -1

            it "And file log should not be created (/usr/local/var/log/cozy/front.log)", ->
                fs.existsSync('/usr/local/var/log/cozy/front.log').should.not.be.ok

            it "And front source should be imported (in /usr/local/cozy/apps/front", ->
                fs.existsSync("#{config('dir_app_bin')}/front").should.be.ok
                fs.existsSync("#{config('dir_app_bin')}/front/package.json").should.be.ok

            it "And front should not be started with port", (done) ->
                clientDS = new Client "http://localhost:#{@port}/"
                clientDS.get '/', (err, res) ->
                    should.not.exist res
                    done()

    describe "Stop application", ->

        describe "Stop application which isn't installed", ->

            it "When I try to stop application", (done) ->
                @timeout 100000
                app =
                    name: "front"
                    type: "static"
                client.post 'apps/front/stop', stop: app, (err, res, body) =>
                    @res = res
                    @body = body
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

        describe "Stop front", ->

            it "When I stop front", (done) ->
                @timeout 100000
                app =
                    name: "front"
                    type: "static"
                client.post 'apps/front/stop', stop:app, (err, res, body) =>
                    @res = res
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And front should not be stopped with port", (done) ->
                clientDS = new Client "http://localhost:#{dsPort}"
                clientDS.get '/', (err, res) ->
                    should.not.exist res
                    done()


    describe "Restart application", ->

        describe "Restart front", ->

            it "When I restart front", (done) ->
                @timeout 100000
                app =
                    name: "front"
                    repository:
                        url: "https://github.com/lemelon/cozy-front.git"
                        type: "git"
                    type: "static"
                client.post 'apps/front/start', "start":app, (err, res, body) =>
                    @res = res
                    @port = body.drone.port
                    dsPort = @port
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And front should not be started with port", (done) ->
                clientDS = new Client "http://localhost:#{@port}"
                clientDS.get '/', (err, res) ->
                    should.not.exist res
                    done()

    describe "Update application", ->

        describe "Update front", ->

            it "When I update front", (done) ->
                @timeout 100000
                app =
                    name: "front"
                    repository:
                        url: "https://github.com/lemelon/front.git"
                        type: "git"
                    type: "static"
                client.post 'apps/front/update', update: app, (err, res, body) =>
                    @res = res
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And front should not start with port", (done) ->
                clientDS = new Client "http://localhost:#{dsPort}"
                clientDS.get '/', (err, res) ->
                    should.not.exist res
                    done()

    describe "Recover all application", ->

        it "When I send request to recover all applications", (done) ->
            client.get 'apps/all', (err, res, body) =>
                @res = res
                @body = body
                done()

        it "Then statusCode should be 200", ->
            @res.statusCode.should.equal 200

        it "And front is in list", ->
            should.exist @body.app
            should.exist @body.app['front']

    describe "Uninstall application", ->

        describe "Uninstall front", ->

            it "When I uninstall front", (done) ->
                @timeout 100000
                app =
                    name: "front"
                    repository:
                        url: "https://github.com/lemelon/cozy-front.git"
                        type: "git"
                    type: "static"
                client.post 'apps/front/uninstall', app, (err, res, body) =>
                    @res = res
                    done()

            it "Then statusCode should be 200", ->
                @res.statusCode.should.equal 200

            it "And front should be stopped but without a port", (done) ->
                clientDS = new Client "http://localhost:#{dsPort}"
                clientDS.get '/', (err, res) ->
                    setTimeout () ->
                        should.not.exist res
                        done()
                    , 1000

            it "And logs file should be removed", ->
                fs.existsSync('/var/log/cozy/front.log').should.not.be.ok

            it "And front repo should be removed", ->
                fs.existsSync('/usr/local/cozy/apps/front').should.not.be.ok

            it "And front has been removed from stack.json", ->
                fs.existsSync(config('file_stack')).should.be.ok
                stack = fs.readFileSync(config('file_stack'), 'utf8')
                exist = stack.indexOf 'front'
                exist.should.equal -1