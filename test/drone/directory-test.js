/*
 * drone-api-test.js: Tests for the `drone` module's RESTful API.
 *
 * (C) 2010, Nodejitsu Inc.
 *
 */

var assert = require('assert'),
    exec = require('child_process').exec,
    fs = require('fs'),
    path = require('path'),
    eyes = require('eyes'),
    request = require('request'),
    vows = require('vows'),
    helpers = require('../helpers'),
    data = require('../fixtures/apps'),
    haibu = require('../../lib/haibu');

var ipAddress = '127.0.0.1',
    port = 9000,
    app = data.apps[0],
    server;

app.user = 'marak';

vows.describe('haibu/drone/directories').addBatch(
  helpers.requireStart(port, function (_server) {
    haibu.config.set('directories:apps', '/usr/local/cozy/apps');
    server = _server;
  })
).addBatch({
  "When using the drone server": {
    "a request against /drones/:id/start": {
      topic: function () {
        var options = {
          uri: 'http://localhost:9000/drones/test/start',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            start : app
          })
        };

        request(options, this.callback);
      },
      "should respond with 200": function (error, response, body) {
        var result = JSON.parse(body);
        assert.equal(response.statusCode, 200);
        assert.isNotNull(result.drone);
        assert.include(result.drone, 'pid');
        assert.include(result.drone, 'port');
        assert.include(result.drone, 'host');
      },
      "test directory should be in '/usr/local/cozy/apps": function (error, response, body) {
        var testFile = "/usr/local/cozy/apps/marak";
        command = 'cd /usr/local/cozy/apps && ls -l | grep marak'
        exec(command, function (err, stdout, stderr) {
          assert.isNotNull(stdout);
        });
      }
    }
  }
}).addBatch({
  "When using the drone server": {
    "a request against /drones/cleanall": {
      topic: function () {
        var options = {
          uri: 'http://localhost:9000/drones/cleanall',
          method: 'POST'
        };

        request(options, this.callback);
      },
      "should respond with 200": function (error, response, body) {
        assert.equal(response.statusCode, 200);
      },
      "should remove the files from the app dir": function (err, response, body) {
        assert.isTrue(!err);
        var files = fs.readdirSync(haibu.config.get('directories:apps'));
        assert.lengthOf(files, 0);
      }
    }
  }
}).addBatch({
  "when the tests are over": {
    topic: function () {
      return false;
    },
    "the server should clean up": function () {
      server.close();
    }
  }
}).export(module);
