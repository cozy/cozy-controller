/*
 * brunch.js: Simple utilities for working with brunch.
 *
 */

var spawn = require('child_process').spawn,
    fs = require('fs'),
    path = require('path'),
    haibu = require('../../haibu');


checkBrunch = function (brunch, callback) {
  brunch.stdout.on('data', function (data) {
    haibu.emit('brunch:build:stdout', 'info', {
      data: data
    });
  });

  brunch.stderr.on('data', function (data) {
    stderr += data;
    haibu.emit('npm:brunch:stderr', 'info', {
      data: data
    });
  });

  brunch.on('exit', function (code) {
    if (code || code == null) {
      var err = new Error('Brunch build failed');
      err.code = code;
      err.result = stderr;
      err.blame = {
        type: 'user',
        message: 'Brunch failed to build'
      };

      haibu.emit('brunch:build:failure', 'info', {
        code: code
      });
      return callback(err);
    } else {
      return callback();
    }
  });
}


brunchBuild = function (dirClient, callback) {
  process.chdir(dirClient);
  if (fs.existsSync(dirClient+'/config-prod.coffee')) {
    var stats = fs.lstatSync(dirClient+'/config-prod.coffee');
    if (stats.isFile()) {
      brunch = spawn('brunch', ['build','--optimize', '--config','config-prod.coffee']);
      checkBrunch(brunch, function (err) {
        callback(err);
      });

    };
  } else {
    brunch = spawn('brunch', ['build', '--optimize']);
    checkBrunch(brunch, function (err) {
      callback(err);
    });
  }
}


//
// ### function build (dirApp, callback)
// #### @callback {function} Continuation to respond to when complete.
// #### @dirApp {string} Path of application directory
// Build brunch if it is necessary.
//
exports.build = function (dirApp, app, callback) {
  // test if ./client exists and if it is a directory
  dirClient = dirApp+'/client'
  if (fs.existsSync(dirClient)) {
    var stats = fs.lstatSync(dirClient);
    if (stats.isDirectory()) {
      // build brunch
      fs.readFile(path.join(dirClient, 'package.json'), function (err, data) {
        if (!err) {
          try {
            pkg = JSON.parse(data);
            pkg.dependencies = pkg.dependencies || {};
            app.dependencies = haibu.common.mixin({}, pkg.dependencies, app.dependencies || {});
            haibu.common.npm.install(dirClient, app, function (err) {
              if (err) {
                return callback(true, err);
              } else {
                brunchBuild(dirClient, function(err) {
                  return callback(true, err);
                });
              }
            });
          }
          catch (err) {
            //
            // Ignore errors
            //
          }
        }
      });
    }
  } else {
    return callback(false);
  }
}


