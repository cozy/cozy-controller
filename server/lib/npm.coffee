path = require 'path'
spawn = require('child_process').spawn
config = require('./conf').get


module.exports.install = (target, callback) => 
    args = [
      'npm',
      # package.json scripts freak out from node-pack in some versions, sudo -u + this are workaround
      '--unsafe-perm', 'true',
      # only use cache for app
      '--cache', path.join(target.dir,'..','.npm'),
      # use blank or non-existent user config
      '--userconfig', path.join(target.dir,'..','.userconfig'),
      # use non-existant user config
      '--globalconfig', path.join(target.dir,'..','.globalconfig'),
      '--production'
    ]
    if config('npm_registry')
        args.push('--registry')     
        args.push(config('npm_registry'))
    if config('npm_strict_ssl')
        args.push('--strict-ssl')     
        args.push(config('npm_strict_ssl'))
    args.push('install')
    options =
        cwd: target.dir
    child = spawn 'sudo', args, options 

    # Kill NPM if this takes more than 5 minutes
    setTimeout(child.kill.bind(child, 'SIGKILL'), 5 * 60 * 1000)

    #child.stdout.on 'data', (data) =>
    stderr = ''
    child.stderr.on 'data', (data) =>
        stderr += data

    child.on 'close', (code) =>
      if code isnt 0
          console.log("npm:install:err: NPM Install failed : #{stderr}")
          err = new Error('NPM Install failed')
          err.code = code
          err.result = stderr
          err.blame = 
              type: 'user'
              message: 'NPM failed to install dependencies'
          callback err
      else
          console.log 'npm:install:success'

      # Remove npm cache
      args = [
          'npm',
          # only use cache for app
          '--cache', path.join(target.dir,'..','.npm'),
          'cache', 'clean',
          '-u',
          target.user
      ]
      options =
          cwd: target.dir
      child = spawn 'sudo', args, options

      #child.stdout.on 'data', (data) =>

      stderr = ''
      child.stderr.on 'data', (data) =>
          stderr += data

      child.on 'close', (code) =>
          if code isnt 0
              console.log 'npm:clean_cache:failure'
              console.log(stderr)

          callback()