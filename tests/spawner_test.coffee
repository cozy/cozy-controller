spawner = require "../server/lib/spawner"

describe "Spawner", ->
    it "When I start an application", (done) ->
        app = 
            name: "test"
        console.log(spawner)
        spawner.start app:app, (err, res) =>
            console.log(err, res)



