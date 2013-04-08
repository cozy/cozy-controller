/*
 * brunch.js: Simple utilities for working with brunch.
 *
 */

var spawn = require('child_process').spawn,
    fs = require('fs'),
    path = require('path'),
    haibu = require('../../haibu');


exports.build = function (dirClient, app, callback) {
  var stderr;

  process.chdir(dirClient);
  if (fs.existsSync(dirClient+'/config-prod.coffee')) {
    var stats = fs.lstatSync(dirClient+'/config-prod.coffee');
    if (stats.isFile()) {
      args = ['build','--optimize', '--config','config-prod.coffee'];
    };
  } else {
    args = ['build', '--optimize'];
  }
  brunch = spawn('brunch', args);

  brunch.stdout.on('data', function (data) {
    haibu.emit('brunch:build:stdout', 'info', {
      data: data
    });
  });

  brunch.stderr.on('data', function (data) {
    stderr = data;
    haibu.emit('brunch:build:stderr', 'info', {
      data: data
    });
  });

  brunch.on('exit', function (code) {
    if (code || code == null) {
      var err = new Error('Brunch build failed');
      err.code = code;
      err.result = stderr;
      err.blame = {
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