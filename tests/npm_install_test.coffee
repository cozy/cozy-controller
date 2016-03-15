helpers = require "./helpers"
client = ""

describe "NPM install", ->

    before helpers.cleanApp
    before (done) ->
        @timeout 10000
        helpers.startApp () =>
            client = helpers.getClient()
            done()

    after (done) ->
        @timeout 20000
        helpers.stopApp done

    it "Install an application through npm", (done) ->
        @timeout 60000
        app =
            name: "contacts"
            package:
                name: "cozy-contacts"
                type: "npm"
            scripts:
                start: "server.coffee"
        url = 'apps/contacts/install'
        client.post url , "start": app, (err, res, body) =>
            @res = res
            @body = body
            @err
            console.log err, body
            done()
