helpers = require "./helpers"
client = helpers.getClient('http://localhost:8888')
should = require('chai').Should()

describe "Spawner", ->

    before helpers.cleanApp 
    before helpers.startApp
    after helpers.stopApp

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

        it "Then statusCode should be 403", ->
            @res.statusCode.should.equal 403


        it "Then body should be 'Application is not authorized'", ->
            @body.should.equal 'Application is not authorized'
