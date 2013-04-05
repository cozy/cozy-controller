haibu = require('../../haibu');


exports.initLog = function() {
  var evNames = [ 'git:clone', 'git:pull', 'npm:install:load','brunch:build'
    ,'npm:install:start','drone:start', 'drone:stop','drone:cleanAll:success',
    'repo:dir:user:create', 'repo:dir:exists' ];
  evNames.forEach(function (name) {
    haibu.on(name, function (message, meta) {
      console.log(message + ": " + name); });
  });

  var errNames = ['error:service' , 'error', 'drone:clean:warning',
    'npm:install:failure','brunch:build:failure', 'drone:cleanAll:warning']
  errNames.forEach(function (name) {
    haibu.on(name, function (message, meta) {
      console.log(message.red.bold + ": "+ name.red.bold + ": \n" +
        JSON.stringify(meta)+ "\n"); });
  });

  var startNames = ['action:start', 'action:stop', 'action:brunch:build',
    'action:light:update','action:clean', 'action:cleanAll, action:restart',
    'action:update']
  startNames.forEach(function (name) {
    haibu.on(name, function (message, meta) {
      datetime = new Date();
      console.log("[" + datetime + "]\n" +
        name.bold + ": " + meta.app.bold + "\n" +
        ">>> perform");
    });
  });

  var succNames = [ 'brunch:build:success','npm:install:sucess',
  'start:success', 'stop:success', "restart:sucess", 'update:success',
  'light:update:success','clean:success', 'cleanAll:success', ];
  succNames.forEach(function (name) {
    haibu.on(name, function (message, meta) {
      console.log(name.green.bold + ": " + meta.app + "\n" +
        "<<< perform\n");
    });
  });
}