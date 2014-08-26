// Generated by CoffeeScript 1.7.1
var exec, path;

path = require('path');

exec = require('child_process').exec;

module.exports.init = (function(_this) {
  return function(app, callback) {
    var commands, err, executeUntilEmpty, match;
    match = app.repository.url.match(/\/([\w\-_\.]+)\.git$/);
    if (!match) {
      err = new Error('Invalid git url: ' + app.repository.url);
      err.blame = {
        type: 'user',
        message: 'Repository configuration present but provides invalid Git URL'
      };
      callback(err);
    }
    commands = ['cd ' + app.appDir + ' && git clone --depth 1 ' + app.repository.url, 'cd ' + app.dir];
    if (app.repository.branch != null) {
      commands[1] += ' && git checkout ' + app.repository.branch;
    }
    commands[1] += ' && git submodule update --init --recursive';
    executeUntilEmpty = function() {
      var clone, command, config, timeout;
      command = commands.shift();
      timeout = setTimeout(function() {
        clone.kill('SIGTERM');
        exec('sudo pkill -9 -f  \'git clone ' + app.repository.url + '\'');
        return callback(err, false);
      }, 300000);
      config = {
        env: {
          "USER": app.user
        }
      };
      return clone = exec(command, config, function(err, stdout, stderr) {
        clearTimeout(timeout);
        if (err != null) {
          return callback(err, false);
        } else if (commands.length > 0) {
          return executeUntilEmpty();
        } else if (commands.length === 0) {
          return callback();
        }
      });
    };
    return executeUntilEmpty();
  };
})(this);

module.exports.update = (function(_this) {
  return function(app, callback) {
    var commands, err, executeUntilEmpty, match;
    match = app.repository.url.match(/\/([\w\-_\.]+)\.git$/);
    if (!match) {
      err = new Error('Invalid git url: ' + app.repository.url);
      err.blame = {
        type: 'user',
        message: 'Repository configuration present but provides invalid Git URL'
      };
      callback(err);
    }
    if (app.repository.branch != null) {
      commands = ['cd ' + app.dir + ' && git reset --hard ', 'cd ' + app.dir + ' && git pull origin ' + app.repository.branch, 'cd ' + app.dir];
    } else {
      commands = ['cd ' + app.dir + ' && git reset --hard ', 'cd ' + app.dir + ' && git pull', 'cd ' + app.dir];
    }
    commands[1] += ' && git submodule update --recursive';
    executeUntilEmpty = function() {
      var command, config;
      command = commands.shift();
      config = {
        env: {
          "USER": app.user
        }
      };
      return exec(command, config, function(err, stdout, stderr) {
        if (err != null) {
          return callback(err, false);
        } else if (commands.length > 0) {
          return executeUntilEmpty();
        } else if (commands.length === 0) {
          return callback();
        }
      });
    };
    return executeUntilEmpty();
  };
})(this);