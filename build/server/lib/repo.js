// Generated by CoffeeScript 1.8.0
var fs, spawn;

fs = require('fs');

spawn = require('child_process').spawn;


/*
    Create repository of <app>
        * Create application directory
        * Change directory permissions
        * Chage directory owner
 */

module.exports.create = function(app, callback) {
  var changeOwner, err, _ref;
  if (((_ref = app.repository) != null ? _ref.type : void 0) === 'git') {
    changeOwner = function(path, callback) {
      var child;
      child = spawn('chown', ['-R', app.user, path]);
      return child.on('exit', function(code) {
        if (code !== 0) {
          return callback(new Error('Unable to change permissions'));
        } else {
          return callback();
        }
      });
    };
    return fs.stat(app.userDir, function(userErr, stats) {
      var createAppDir;
      createAppDir = function() {
        return fs.stat(app.appDir, function(droneErr, stats) {
          if (droneErr != null) {
            fs.mkdir(app.appDir, "0755", function(mkAppErr) {
              return changeOwner(app.appDir, function(err) {
                if (mkAppErr != null) {
                  return callback(mkAppErr, false);
                }
              });
            });
          }
          return callback(null, true);
        });
      };
      if (userErr != null) {
        return fs.mkdir(app.userDir, "0755", function(mkUserErr) {
          return changeOwner(app.userDir, function(err) {
            if (mkUserErr != null) {
              callback(mkUserErr, false);
            }
            return createAppDir();
          });
        });
      } else {
        return createAppDir();
      }
    });
  } else {
    err = new Error("Controller can spawn only git repo");
    return callback(err);
  }
};


/*
    Delete repository of <app>
        * Remove app directory
        * Remove log files
 */

module.exports["delete"] = function(app, callback) {
  var child;
  child = spawn('rm', ['-rf', app.userDir]);
  return child.on('exit', function(code) {
    if (code !== 0) {
      return callback(new Error('Unable to remove directory'));
    } else {
      return fs.unlink(app.logFile, function(err) {
        if (fs.existsSync(app.backup)) {
          return fs.unlink(app.backup, function(err) {
            return callback();
          });
        } else {
          return callback();
        }
      });
    }
  });
};
