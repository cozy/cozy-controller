/*
 * brunch.js: Simple utilities for working with brunch.
 *
 */

var spawn = require('child_process').spawn,
    fs = require('fs'),
    haibu = require('../../haibu');


brunchBuild = function (dirClient, callback) {
	console.log("brunchBuild");
	process.chdir(dirClient);
	if (fs.existsSync(dirClient+'/config-prod.coffee')) {
		var stats = fs.lstatSync(dirClient+'/config-prod.coffee');
    if (stats.isFile()) {
    	brunch = spawn('brunch', ['build','--config','config-prod.coffee']);
    	brunch.stderr.setEncoding('utf8');
			brunch.stderr.on('close', function(code) {
				if (code != 0) {
					return callback("brunch");
				} else {
					return callback();
				}
			});
		};
	} else {
		brunch = spawn('brunch', ['build']);
		brunch.on('close', function(code) {
			if (code != 0) {
				return callback("brunch");
			} else {
				console.log("callback");
				return callback();
			}
		});
	}
}


//
// ### function build (dirApp, callback)
// #### @callback {function} Continuation to respond to when complete.
// #### @dirApp {string} Path of application directory
// Build brunch if it is necessary.
//
exports.build = function (dirApp, callback) {
	// test if ./client exists and if it is a directory
	if (fs.existsSync(dirApp+'/client')) {
		var stats = fs.lstatSync(dirApp+'/client');
    if (stats.isDirectory()) {
    	// build brunch
    	process.chdir(dirApp+'/client');
    	npm = spawn('npm', ['install']);
    	npm.on('close', function(code) {
    		if (code != 0) {
    			return callback(true, "npm");
    		} else {
					brunchBuild(dirApp+'/client', function(err) {
						return callback(true, err);
					});
    		}
    	});
		}
	} else {
		return callback(false);
	}
}


