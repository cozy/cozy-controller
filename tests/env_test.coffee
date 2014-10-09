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
                        "TEST": "test"
                    "home":
                        "COZY": "true"
                    "global":
                        "GLOBAL": "testGlobal"
                npm_registry: false
                npm_strict_ssl: false
            fs.writeFileSync '/etc/cozy/controller.json', JSON.stringify(config)
            conf.init () =>
                done()

        it "Then I recover configuration", ->
            should.exist conf.get('env').global
            should.exist conf.get('env').global.GLOBAL
            conf.get('env').global.GLOBAL.should.equal "testGlobal"

            should.exist conf.get('env').home
            should.exist conf.get('env').home.COZY
            conf.get('env').home.COZY.should.equal "true"

            should.exist conf.get('env').proxy
            conf.get('env').proxy.should.equal false

            should.exist conf.get('env')['data-system']
            should.exist conf.get('env')['data-system'].TEST
            conf.get('env')["data-system"].TEST.should.equal "test"

            should.exist conf.get('npm_registry')
            conf.get('npm_registry').should.equal false
            # TODOS : test if npm use correct options.

            should.exist conf.get('npm_strict_ssl')
            conf.get('npm_strict_ssl').should.equal false

    describe "Environment transmission", ->

        it "When I install applicatino test", (done) ->
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
                done()

        it "Then application test should have environment variables", ->
            data = require '/usr/local/cozy/apps/data-system/test-env.json'
            data.name.should.equal 'data-system'
            data.global.should.equal 'testGlobal'
            data.test.should.equal 'test'