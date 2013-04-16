/*
 * brunch.js: Simple utilities for working with brunch.
 *
 */

var exec = require('child_process').exec,
    fs = require('fs'),
    path = require('path'),
    haibu = require('../../haibu');

//
// ### function build (dirClient, target, callback)
// #### @dirClient {Repository} repository to build.
// #### @target {App} application to build
// #### @callback {function} Continuation passed to respond to.
// Brunch build application target
//
exports.build = function (dirClient, app, callback) {
  var stderr;

  //
  // Configure brunch build
  //
  command = 'cd ' + dirClient + ' && '
  if (fs.existsSync(dirClient + '/config-prod.coffee')) {
    var stats = fs.lstatSync(dirClient + '/config-prod.coffee');
    if (stats.isFile()) {
      command += 'brunch build --optimize --config config-prod.coffee';
    };
  } else {
    command += 'brunch build --optimize';
  }

  //
  // Brunch build
  //
  exec(command, function (err, stdout, stderr) {
    //
    // Check brunch build
    //
    if (err !== null) {
      haibu.emit('brunch:build:failure', 'error', {
        dir: clientDir,
        app: app.name,
        error: err.message,
        command: command
      });
      callback(err, false);
    } else {
      haibu.emit('brunch:build', 'info', {
        stdout: stdout
      })
      callback();
    }
  })
}