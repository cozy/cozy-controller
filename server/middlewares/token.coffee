token = ""

module.exports.init = (current_token) =>
    token = current_token

module.exports.check = (req, res, next) =>
    if process.env.NODE_ENV is "production" or process.env.NODE_ENV is "test"
        auth = req.headers['x-auth-token']
        if auth isnt "undefined" and auth?
            if auth isnt token
                res.send 403, "Application is not authorized"
            else
                next()
        else
            res.send 401,  "Application is not authenticated"
    else
        next()


module.exports.get = () =>
    return token