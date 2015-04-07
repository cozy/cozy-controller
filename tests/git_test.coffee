helpers = require "./helpers"
client = ""
should = require('chai').Should()

describe "Git", ->

    before helpers.cleanApp
    before (done) ->
        @timeout 10000
        helpers.startApp () =>
            client = helpers.getClient()
            done()

    after (done) ->
        @timeout 10000
        helpers.stopApp done

    describe "Try to install an application with a bad git repository", ->

        it "When I try to install an application with a bad git repository", (done) ->
            @timeout 20000
            app =
                name: "data-system"
                repository:
                    url: "https://github.com/cozy/cozy-data-systel.git"
                    type: "git"
                scripts:
                    start: "server.coffee"
            client.post 'apps/data-systel/install', "start": app, (err, res, body) =>
                @res = res
                @body = body
                @err
                done()

        it "Then statusCode should be 400", ->
            @res.statusCode.should.equal 400


        it "Then body.error should be 'Error: Invalid Git url: https://github.com/cozy/cozy-data-systel.git'", ->
            string = 'Error: Invalid Git url: https://github.com/cozy/cozy-data-systel.git'
            @body.message.should.equal string