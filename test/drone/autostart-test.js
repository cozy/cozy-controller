/*
 * autostart-test.js: Tests for autostarting drones.
 *
 * (C) 2010, Nodejitsu Inc.
 *
 */

var assert = require('assert'),
    path = require('path'),
    vows = require('vows'),
    data = require('../fixtures/apps'),
    helpers = require('../helpers'),
    haibu = require('../../lib/haibu');

var app = data.apps[0];
var home = data.apps[3];
var dataSystem = data.apps[4];

//
// Add a user property to the app
//
app.user = 'marak';

haibu.config.set('directories:pid', '/etc/cozy/pids');

vows.describe('haibu/drone/autostart').addBatch(helpers.requireInit()).addBatch({
  "When using haibu": {
    "a call to haibu.drone.start()": {
      topic: function () {
        haibu.drone.start({
          host: 'localhost',
          port: 9100
        }, this.callback);
      },
      "should namespace the server and drone": function (err, server) {
        assert.isNull(err);
        assert.isObject(haibu.running);
        assert.isObject(haibu.running.server);
        assert.isObject(haibu.running.drone);
      },
      "and running one drone": {
        topic: function (server) {
          server.drone.start(app, this.callback);
        },
        "should be successfull": function (err, drone) {
          assert.isNull(err);
        }
      }
    }
  }
}).addBatch({
  "Stopping server": {
    topic: function () {
      haibu.drone.stop(false, this.callback);
    },
    "should be successfull": function () {
      assert.lengthOf(Object.keys(haibu.running), 0);
    }
  }
}).addBatch({
  "When using haibu": {
    "a call to haibu.drone.start()": {
      topic: function () {
        haibu.drone.start({
          host: 'localhost',
          port: 9100
        }, this.callback);
      },
      "should namespace the server and drone": function (err, server) {
        assert.isNull(err);
        assert.isObject(haibu.running);
        assert.isObject(haibu.running.server);
        assert.isObject(haibu.running.drone);
      },
      "and a resulting server": {
        topic: function (server) {
          this.callback(null, server)
        },
        "should be running `test` app": function (err, server) {
          assert.isNotNull(server.drone.apps.test);
          assert.equal(Object.keys(server.drone.apps.test.drones).length, 1);
        }
      },
      "Add application home": {
        topic: function (server) {
          server.drone.start(home, this.callback);
        },
        "should be successfull": function (err, drone) {
          assert.isNull(err);
        },
      },
      "Add application data-system": {
        topic: function (server) {
          server.drone.start(dataSystem, this.callback);
        },
        "should be successfull": function (err, drone) {
          assert.isNull(err);
        }
      }
    }
  }
}).addBatch({
  "Stoping server ": {
    topic: function () {
      haibu.drone.stop(false, this.callback);
    },
    "should be successfull": function () {
      assert.lengthOf(Object.keys(haibu.running), 0);
    }
  }
}).addBatch({
  "When using haibu": {
    "a call to haibu.drone.start()": {
      topic: function () {
        haibu.drone.start({
          host: 'localhost',
          port: 9100
        }, this.callback);
      },
      "should namespace the server and drone": function (err, server) {
        assert.isNull(err);
        assert.isObject(haibu.running);
        assert.isObject(haibu.running.server);
        assert.isObject(haibu.running.drone);
      },
      "and a resulting server": {
        topic: function (server) {
          this.callback(null, server)
        },
        "should be running `test` app, home and data-system": function (err, server) {
          assert.equal(Object.keys(haibu.running.drone.apps).length, 3);
        }
      }
    }
  }
}).addBatch({
  "When the tests are over": {
    topic: function () {
      haibu.drone.stop(this.callback);
    },
    "the server should clean up": function () {
      assert.lengthOf(Object.keys(haibu.running), 0);
    }
  }
}).export(module);

