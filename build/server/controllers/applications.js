// Generated by CoffeeScript 1.10.0
var async, config, controller, error, error1, exec, latest, log, pkg, restartController, sendError, updateController, updateMonitor;

config = require('../lib/conf').get;

controller = require('../lib/controller');

async = require('async');

log = require('printit')({
  date: true,
  prefix: 'controllers:applications'
});

exec = require('child_process').exec;

latest = require('latest');

try {
  pkg = require('../../package.json');
} catch (error1) {
  error = error1;
  pkg = require('../../../package.json');
}

sendError = function(res, err, code) {
  if (code == null) {
    code = 500;
  }
  if (err == null) {
    err = {
      stack: null,
      message: "Server error occured"
    };
  }
  console.log("Sending error to client: ");
  console.log(err.stack);
  return res.status(code).send({
    error: err.message,
    success: false,
    message: err.message,
    stack: err.stack,
    code: err.code != null ? err.code : void 0
  });
};

updateController = function(callback) {
  return latest('cozy-controller', function(err, version) {
    if ((err == null) && version !== pkg.version) {
      log.info("controller: update");
      return exec("npm -g update cozy-controller", function(err, stdout, stderr) {
        if (err || stderr) {
          return callback("Error during controller update: " + stderr);
        } else {
          return callback();
        }
      });
    } else {
      return callback();
    }
  });
};

updateMonitor = function(callback) {
  if (this.blockMonitor) {
    return callback();
  } else {
    log.info("monitor: update");
    return exec("npm -g update cozy-monitor", function(err, stdout, stderr) {
      if (err) {
        return callback("Error during monitor update: " + stderr);
      } else if (stderr) {
        log.warn(stderr);
        return callback();
      } else {
        return callback();
      }
    });
  }
};

restartController = function(callback) {
  return exec(config('restart_cmd'), function(err, stdout) {
    if (err) {
      return callback("The controller can't be restarted. You should " + "configure the command in /etc/cozy/controller.json.");
    } else {
      log.info("Controller was successfully restarted.");
      return callback();
    }
  });
};


/*
    Install application.
        * Check if application is declared in body.start
        * if application is already installed, just start it
 */

module.exports.install = function(req, res, next) {
  var err, manifest;
  if (req.body.start == null) {
    err = new Error("Manifest should be declared in body.start");
    return sendError(res, err, 400);
  }
  manifest = req.body.start;
  return controller.install(req.connection, manifest, function(err, result) {
    if (err != null) {
      log.error(err.toString());
      return sendError(res, err, 400);
    } else {
      if (result.type === 'static') {
        return res.status(200).send({
          drone: {
            type: result.type,
            path: result.dir
          }
        });
      } else {
        return res.status(200).send({
          drone: {
            port: result.port
          }
        });
      }
    }
  });
};


/*
    Change application branch.
        * Try to stop application
        * Change application branch
        * Start application if necessary
 */

module.exports.changeBranch = function(req, res, next) {
  var manifest, name, newBranch, started;
  manifest = req.body.manifest;
  name = req.params.name;
  newBranch = req.params.branch;
  started = true;
  return controller.stop(name, function(err, result) {
    var conn;
    if ((err != null) && err.toString() === 'Error: Cannot stop an application not started') {
      return started = false;
    } else if (err != null) {
      log.error(err.toString());
      return sendError(res, err, 400);
    } else {
      conn = req.connection;
      return controller.changeBranch(conn, manifest, newBranch, function(err, result) {
        if (err != null) {
          log.error(err.toString());
          return sendError(res, err, 400);
        } else {
          if (!started) {
            return res.status(200).send({});
          } else {
            return controller.start(manifest, function(err, result) {
              if (err != null) {
                log.error(err.toString());
                return sendError(res, err, 400);
              } else {
                return res.status(200).send({
                  drone: {
                    "port": result.port
                  }
                });
              }
            });
          }
        }
      });
    }
  });
};


/*
    Start application
        * Check if application is declared in body.start
        * Check if application is installed
        * Start application
 */

module.exports.start = function(req, res, next) {
  var err, manifest;
  if (req.body.start == null) {
    err = new Error("Manifest should be declared in body.start");
    return sendError(res, err, 400);
  }
  manifest = req.body.start;
  return controller.start(manifest, function(err, result) {
    if (err != null) {
      log.error(err.toString());
      err = new Error(err.toString());
      return sendError(res, err, 400);
    } else {
      return res.status(200).send({
        drone: {
          port: result.port,
          type: result.type,
          path: result.path
        }
      });
    }
  });
};


/*
    Stop application
        * Check if application is installed
        * Stop application
 */

module.exports.stop = function(req, res, next) {
  var name;
  name = req.params.name;
  if (req.body.stop.type === 'static') {
    return res.status(200).send({});
  } else {
    return controller.stop(name, function(err, result) {
      if (err != null) {
        log.error(err.toString());
        err = new Error(err.toString());
        return sendError(res, err, 400);
      } else {
        return res.status(200).send({
          app: result
        });
      }
    });
  }
};


/*
    Uninstall application
        * Check if application is installed
        * Uninstall application
 */

module.exports.uninstall = function(req, res, next) {
  var name, purge;
  name = req.params.name;
  purge = req.body.purge != null;
  return controller.uninstall(name, purge, function(err, result) {
    if (err != null) {
      log.error(err.toString());
      err = new Error(err.toString());
      return sendError(res, err, 400);
    } else {
      return res.status(200).send({
        app: result
      });
    }
  });
};


/*
    Update application
        * Check if application is installed
        * Update appplication
 */

module.exports.update = function(req, res, next) {
  var manifest;
  manifest = req.body.update;
  return controller.update(req.connection, manifest, function(err, result) {
    if (err != null) {
      log.error(err.toString());
      err = new Error(err.toString());
      return sendError(res, err, 400);
    } else {
      return res.status(200).send({
        drone: {
          port: result.port
        }
      });
    }
  });
};


/*
    Update application
        * Check if application is installed
        * Update appplication
 */

module.exports.updateStack = function(req, res, next) {
  var options;
  options = req.body;
  return async.eachSeries(['data-system', 'proxy', 'home'], function(app, callback) {
    return controller.stop(app, function(err, res) {
      if (err != null) {
        return callback(err);
      }
      return controller.update(req.connection, app, function(err, res) {
        return callback(err);
      });
    });
  }, function(err) {
    if (err != null) {
      return restartController(function(error) {
        log.error(err.toString());
        err = new Error("Cannot update stack: " + (err.toString()));
        return sendError(res, err, 400);
      });
    } else {
      return async.retry(3, updateMonitor.bind(options), function(err, result) {
        if (err != null) {
          log.error(err.toString());
        }
        return async.retry(3, updateController, function(err, result) {
          if (err != null) {
            log.error(err.toString());
            err = new Error("Cannot update stack: " + (err.toString()));
            return sendError(res, err, 400);
          } else {
            return restartController(function(err) {
              if (err != null) {
                log.error(err.toString());
                err = new Error("Cannot update stack: " + (err.toString()));
                return sendError(res, err, 400);
              } else {
                return res.status(200).send({});
              }
            });
          }
        });
      });
    }
  });
};


/*
    Reboot controller
 */

module.exports.restartController = function(req, res, next) {
  return restartController(function(err) {
    if (err != null) {
      log.error(err.toString());
      err = new Error(err.toString());
      return sendError(res, err, 400);
    } else {
      return res.status(200).send({});
    }
  });
};


/*
    Return a list with all applications
 */

module.exports.all = function(req, res, next) {
  return controller.all(function(err, result) {
    if (err != null) {
      log.error(err.toString());
      err = new Error(err.toString());
      return sendError(res, err, 400);
    } else {
      return res.status(200).send({
        app: result
      });
    }
  });
};


/*
    Return a list with all started applications
 */

module.exports.running = function(req, res, next) {
  return controller.running(function(err, result) {
    if (err != null) {
      log.error(err.toString());
      err = new Error(err.toString());
      return sendError(res, err, 400);
    } else {
      return res.status(200).send({
        app: result
      });
    }
  });
};
