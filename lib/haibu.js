/*
 * haibu.js: Top level include for the haibu module
 *
 * (C) 2010, Nodejitsu Inc.
 *
 */

var fs = require('fs'),
    path = require('path'),
    flatiron = require('flatiron'),
    winston = require('winston'),
    util = require('util'),
    semver = require('semver');

var haibu = module.exports = new flatiron.App({
  delimiter: ':',
  root: path.join(__dirname, '..'),
  directories: {
    apps: '#ROOT/local',
    autostart: '#ROOT/autostart',
    config: '#ROOT/config',
    packages: '#ROOT/packages',
    tmp: '#ROOT/tmp'
  }
});


var evNames = [ 'git:clone', 'git:pull', 'brunch:build:start','npm:install:load'
  ,'npm:install:start','drone:start', 'drone:stop', 'start:start'];
evNames.forEach(function (name) {
  haibu.on(name, function (message, meta) { console.log(message + ": " +
    name.bold); });
});

var errNames = ['error:service' , 'error', 'npm:install:stderr',
  'npm:install:failure', 'brunch:build:stderr', 'brunch:build:failure']
errNames.forEach(function (name) {
  haibu.on(name, function (message, meta) { console.log(message.red.bold + ": " +
    name.red.bold + ": \n" + JSON.stringify(meta)+ "\n"); });
});

var succNames = [ 'brunch:build:success','npm:install:sucess',
'start:success', 'stop:success'];
succNames.forEach(function (name) {
  haibu.on(name, function (message, meta) { console.log(message + ": " +
    name.green.bold + ": \n" + JSON.stringify(meta)+ "\n"); });
});

haibu.use(flatiron.plugins.exceptions);

//
// Expose version through `pkginfo`.
//
require('pkginfo')(module, 'version');

//
// Set the allowed executables
//
haibu.config.set('allowedExecutables', ['node', 'coffee']);


haibu.common     = haibu.utils = require('./haibu/common');
haibu.Spawner    = require('./haibu/core/spawner').Spawner;
haibu.repository = require('./haibu/repositories');
haibu.drone      = require('./haibu/drone');
haibu.running    = {};

haibu.sendResponse = function sendResponse(res, status, body) {
  return res.json(status, body);
};

//
// Expose the relevant plugins as lazy-loaded getters
//
['coffee', 'advanced-replies', 'useraccounts'].forEach(function (plugin) {
  haibu.__defineGetter__(plugin, function () {
    return require('./haibu/plugins/' + plugin);
  });
})