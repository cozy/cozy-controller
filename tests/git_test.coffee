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
                done()

        it "Then statusCode should be 400", ->
            @res.statusCode.should.equal 400


        it "Then body.error.message should be 'Repository configuration present but provides invalid Git URL'", ->
            should.exist @body.error
            should.exist @body.error.blame
            should.exist @body.error.blame.message
            @body.error.blame.message.should.equal 'Repository configuration present but provides invalid Git URL'