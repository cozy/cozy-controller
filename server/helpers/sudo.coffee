spawn = require('child_process').spawn

# Hack: we force $HOME, because it was not set correctly for old apps
module.exports = (user, dir, command) ->
    options = cwd: dir
    args = ['-n', '-u', user, 'env', "HOME=#{dir}"].concat command
    spawn 'sudo', args, options

