helpers = require "./helpers"
should = require('chai').Should()
server = ""
client = ""

describe "Token", ->


    before (done) ->
        @timeout 100000
        helpers.startApp (appli) =>
            port = appli.server._connectionKey.slice(-4)
            client = helpers.getClient "http://localhost:#{port}"
            done()
    after (done) ->
        @timeout 10000
        helpers.stopApp done

    describe "Request without token", ->

        it "When I send request without token", (done) ->
            client.get 'diskinfo', (err, res, body) =>
                @res = res
                @body = body
                done()

        it "Then statusCode should be 401", ->
            @res.statusCode.should.equal 401


        it "Then body should be 'Application is not authenticated'", ->
            @body.should.equal 'Application is not authenticated'

    describe "Request with bad token", ->

        before  =>
            client.setToken('bad_token')

        it "When I send request without token", (done) ->
            client.get 'diskinfo', (err, res, body) =>
                @res = res
                @body = body
                done()

        it "Then statusCode should be 401", ->
            @res.statusCode.should.equal 401


        it "Then body should be 'Token is not correct'", ->
            @body.should.equal 'Token is not correct'
