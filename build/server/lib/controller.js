// Generated by CoffeeScript 1.10.0
var App, async, config, directory, drones, fs, gitInstall, installDependencies, log, npm, npmInstall, path, repo, running, spawner, stack, stackApps, startApp, stopApp, stopApps, type, updateApp, user,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

fs = require('fs');

spawner = require('./spawner');

npm = require('./npm');

repo = require('./repo');

directory = require('./directory');

user = require('./user');

stack = require('./stack');

config = require('./conf').get;

log = require('printit')({
  date: true,
  prefix: 'lib:controller'
});

type = [];

type['git'] = require('./git');

type['npm'] = require('./npm_installer');

App = require('./app').App;

path = require('path');

async = require('async');

drones = {};

running = {};

stackApps = ['home', 'data-system', 'proxy'];


/*
    Start Application <app>
        * check if application isn't started
        * start process
        * add application in drones and running
 */

startApp = function(app, callback) {
  var err;
  if (running[app.name] != null) {
    err = new Error('Application already exists');
    return callback(err);
  } else {
    if (app.type === 'static') {
      return callback(null, app);
    } else {
      return spawner.start(app, function(err, result) {
        var ref;
        if (err != null) {
          return callback(err);
        } else if (result == null) {
          err = new Error('Unknown error from Spawner.');
          return callback(err);
        } else {
          drones[app.name] = result.pkg;
          running[app.name] = result;
          if (ref = app.name, indexOf.call(stackApps, ref) >= 0) {
            return stack.addApp(app, function(err) {
              return callback(null, result);
            });
          } else {
            return callback(null, result);
          }
        }
      });
    }
  }
};


/*
    Stop all applications in tab <apps>
 */

stopApps = function(apps, callback) {
  var app;
  if (apps.length > 0) {
    app = apps.pop();
    return stopApp(app, function() {
      log.info(app + ":stop application");
      return stopApps(apps, callback);
    });
  } else {
    drones = [];
    return callback();
  }
};


/*
    Stop application <name>
        * Stop process
        * Catch event exit (or error)
        * Delete application in running
 */

stopApp = function(name, callback) {
  var err, error1, monitor, onErr, onStop;
  monitor = running[name].monitor;
  onStop = function() {
    monitor.removeListener('error', onErr);
    monitor.removeListener('exit', onStop);
    monitor.removeListener('stop', onStop);
    return callback(null, name);
  };
  onErr = function(err) {
    log.error(err);
    monitor.removeListener('stop', onStop);
    monitor.removeListener('exit', onStop);
    return callback(err, name);
  };
  monitor.once('stop', onStop);
  monitor.once('exit', onStop);
  monitor.once('error', onErr);
  try {
    delete running[name];
    return monitor.stop();
  } catch (error1) {
    err = error1;
    log.error(err);
    return onErr(err);
  }
};

gitInstall = function(app, connection, callback) {
  log.info(app.name + ":git clone");
  return type[app.repository.type].init(app, function(err) {
    if (err != null) {
      if (err.code == null) {
        err.code = 2;
      }
      err.code = 20 + err.code;
      return callback(err);
    } else {
      log.info(app.name + ":npm install dependencies");
      return installDependencies(connection, app, 2, function(err) {
        if (err != null) {
          err.code = 3;
        }
        return callback(err);
      });
    }
  });
};

npmInstall = function(app, connection, callback) {
  log.info(app.name + ":npm install");
  return type['npm'].init(app, function(err) {
    if (err != null) {
      err.code = 3;
    }
    return callback(err);
  });
};


/*
    Update application <name>
        * Recover drone
        * Git pull
        * install new dependencies
 */

updateApp = function(connection, app, callback) {
  log.info(app.name + ":update application");
  return type[app.repository.type].update(app, function(err) {
    if (err != null) {
      return callback(err);
    } else {
      return installDependencies(connection, app, 2, function(err) {
        if (err != null) {
          return callback(err);
        } else {
          return callback(null, app);
        }
      });
    }
  });
};


/*
    Install depdencies of application <app> <test> times
        * Try to install dependencies (npm install)
        * If installation return an error, try again (if <test> isnt 0)
 */

installDependencies = function(connection, app, test, callback) {
  test = test - 1;
  return npm.install(connection, app, function(err) {
    if ((err != null) && test === 0) {
      return callback(err);
    } else if (err != null) {
      log.info('Try again to install NPM dependencies...');
      return installDependencies(connection, app, test, callback);
    } else {
      return callback();
    }
  });
};


/*
    Remove application <name> from running
        Userfull if application exit with timeout
 */

module.exports.removeRunningApp = function(name) {
  return delete running[name];
};


/*
    Install applicaton defineed by <manifest>
        * Check if application isn't already installed
        * Create user cozy-<name> if necessary
        * Create application repo for source code
        * Clone source in repo
        * Install dependencies
        * If application is a stack application, add application in stack.json
        * Start process
    Error code :
        1 -> Error in user creation
        2- -> Error in code source retrieval
            20 -> Git repo doesn't exist
            21 -> Can"t access to github
            22 -> Git repo exist but it receives an error during clone
        3 -> Error in dependencies installation (npm)
        4 -> Error in application starting
 */

module.exports.install = function(connection, manifest, callback) {
  var app;
  app = new App(manifest).app;
  if (drones[app.name] != null) {
    log.info(app.name + ":already installed");
    log.info(app.name + ":start application");
    return startApp(drones[app.name], callback);
  } else if (fs.existsSync(app.dir)) {
    log.info(app.name + ":already installed");
    log.info(app.name + ":start application from dir");
    return startApp(app, callback);
  } else {
    drones[app.name] = app;
    return async.series([
      function(cb) {
        return user.create(app, function(err) {
          if (err != null) {
            err.code = 1;
          }
          return cb(err);
        });
      }, function(cb) {
        return directory.create(app, cb);
      }, app["package"] ? function(cb) {
        return npmInstall(app, connection, cb);
      } : function(cb) {
        return gitInstall(app, connection, cb);
      }
    ], function(err) {
      if (err) {
        return callback(err);
      }
      log.info(app.name + ":start application");
      return startApp(app, function(err, result) {
        if (err != null) {
          err.code = 4;
        }
        return callback(err, result);
      });
    });
  }
};


/*
    Start aplication defined by <manifest>
        * Check if application is installed
        * Start process
 */

module.exports.start = function(manifest, callback) {
  var app, err, error, error1;
  try {
    app = new App(manifest).app;
  } catch (error1) {
    error = error1;
    return callback(new Error("Can't retrieve application manifest,\npackage.json should be JSON format " + error));
  }
  if ((drones[app.name] != null) || fs.existsSync(app.dir)) {
    drones[app.name] = app;
    return startApp(app, function(err, result) {
      if (err != null) {
        return callback(err);
      } else {
        return callback(null, result);
      }
    });
  } else {
    err = new Error('Cannot start an application not installed');
    return callback(err);
  }
};


/*
    Change aplication branch
        * Git checkout
        * Install dependencies
 */

module.exports.changeBranch = function(connection, manifest, newBranch, callback) {
  var app;
  app = new App(manifest).app;
  log.info(app.name + ":git checkout");
  return type['git'].changeBranch(app, newBranch, function(err) {
    if (err != null) {
      if (err.code == null) {
        err.code = 2;
      }
      err.code = 20 + err.code;
      return callback(err);
    } else {
      manifest.repository.branch = newBranch;
      log.info(app.name + ":npm install");
      return installDependencies(connection, app, 2, function(err) {
        if (err != null) {
          err.code = 3;
          return callback(err);
        } else {
          return callback();
        }
      });
    }
  });
};


/*
    Stop application <name>
        * Check if application is started
        * Stop process
 */

module.exports.stop = function(name, callback) {
  var err;
  if (running[name] != null) {
    return stopApp(name, callback);
  } else {
    err = new Error('Cannot stop an application not started');
    return callback(err);
  }
};


/*
    Stop all started applications
        Useful when controller is stopped
 */

module.exports.stopAll = function(callback) {
  return stopApps(Object.keys(running), callback);
};


/*
    Uninstall application <name>
        * Check if application is installed
        * Stop application if appplication is started
        * Remove from stack.json if application is a stack application
        * Remove code source
        * Delete application from drones (and running if necessary)
 */

module.exports.uninstall = function(name, purge, callback) {
  var app, err, userDir;
  if (purge == null) {
    purge = false;
  }
  if (drones[name] != null) {
    if (running[name] != null) {
      log.info(name + ":stop application");
      running[name].monitor.stop();
      delete running[name];
    }
    if (indexOf.call(stackApps, name) >= 0) {
      log.info(name + ":remove from stack.json");
      stack.removeApp(name, function(err) {
        if (err != null) {
          return log.error(err);
        }
      });
    }
    app = drones[name];
    if (purge) {
      log.info(name + ":delete directory");
      directory.remove(app, function(err) {
        if (err != null) {
          return log.error(err);
        }
      });
    }
    return repo["delete"](app, function(err) {
      log.info(name + ":delete source");
      if (drones[name] != null) {
        delete drones[name];
      }
      if (err != null) {
        return callback(err);
      } else {
        return callback(null, name);
      }
    });
  } else {
    userDir = path.join(config('dir_app_bin'), name);
    if (fs.existsSync(userDir)) {
      app = {
        name: name,
        dir: userDir,
        logFile: config('dir_app_log') + name + ".log",
        errFile: config('dir_app_log') + name + "-err.log",
        backup: config('dir_app_log') + name + ".log-backup"
      };
      if (purge) {
        log.info(name + ":delete directory");
        directory.remove(app, function(err) {
          if (err != null) {
            return log.error(err);
          }
        });
      }
      return repo["delete"](app, function(err) {
        log.info(name + ":delete source");
        if (drones[name] != null) {
          delete drones[name];
        }
        if (err != null) {
          return callback(err);
        } else {
          return callback(null, name);
        }
      });
    } else {
      err = new Error('Cannot uninstall an application not installed');
      return callback(err);
    }
  }
};


/*
    Update an application <name>
        * Check if application is installed
        * Stop application if application is started
        * Update code source (git pull / npm install)
        * Restart application if it was started
 */

module.exports.update = function(connection, manifest, callback) {
  var app, base, err;
  if (indexOf.call(stackApps, manifest) >= 0) {
    manifest = drones[manifest];
    if (manifest.repository == null) {
      manifest.repository = {};
    }
    if ((base = manifest.repository).type == null) {
      base.type = 'npm';
    }
  }
  app = new App(manifest).app;
  if (drones[app.name] != null) {
    if (running[app.name] != null) {
      log.info(app.name + ":stop application");
      return stopApp(app.name, function(err) {
        return updateApp(connection, app, function(err) {
          if (err != null) {
            return callback(err);
          } else {
            return startApp(app, function(err, result) {
              log.info(app.name + ":start application");
              return callback(err, result);
            });
          }
        });
      });
    } else {
      return updateApp(connection, app, callback);
    }
  } else {
    err = new Error('Application is not installed');
    log.error(err);
    return callback(err);
  }
};


/*
    Add application <app> in drone
        Useful for autostart
 */

module.exports.addDrone = function(app, callback) {
  drones[app.name] = app;
  return callback();
};


/*
    Return all applications (started or stopped)
 */

module.exports.all = function(callback) {
  var apps, i, key, len, ref;
  apps = {};
  ref = Object.keys(drones);
  for (i = 0, len = ref.length; i < len; i++) {
    key = ref[i];
    apps[key] = drones[key];
  }
  return callback(null, apps);
};


/*
    Return all started applications
 */

module.exports.running = function(callback) {
  var apps, i, key, len, ref;
  apps = {};
  ref = Object.keys(running);
  for (i = 0, len = ref.length; i < len; i++) {
    key = ref[i];
    apps[key] = drones[key];
  }
  return callback(null, apps);
};
