helpers = require "./helpers"
fs = require 'fs'
should = require('chai').Should()
client = ""
conf = require('../server/lib/conf')


describe "Environment variable", ->

    before helpers.cleanApp
    before (done) ->
        @timeout 100000
        helpers.startApp () =>
            client = helpers.getClient()
            done()
    after (done) ->
        @timeout 10000
        helpers.stopApp done

    describe "Initialization", ->

        it "When I initialize configuration", (done) ->
            config =
                env:
                    "data-system":
                        "COZY": "true"
                    "home":
                        "COZY": "true"
                    "global":
                        "TEST1": "firstTest"
                        "TEST2": "secondTest"
            fs.writeFileSync '/etc/cozy/controller.json', JSON.stringify(config)
            conf.init () =>
                done()

        it "Then I recover configuration", ->
            should.exist conf.get('env').global
            should.exist conf.get('env').global.TEST1
            conf.get('env').global.TEST1.should.equal "firstTest"
            should.exist conf.get('env').global.TEST2
            conf.get('env').global.TEST2.should.equal "secondTest"

            should.exist conf.get('env').home
            should.exist conf.get('env').home.COZY
            conf.get('env').home.COZY.should.equal "true"

            should.exist conf.get('env').proxy
            conf.get('env').proxy.should.equal false

            should.exist conf.get('env')['data-system']
            should.exist conf.get('env')['data-system'].COZY
            conf.get('env')["data-system"].COZY.should.equal "true"

    describe "Environment transmission", ->

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

        it "Then data-system should have environment variables", ->
            #console.log forever.list()
            console.log "TODOS !!! "
