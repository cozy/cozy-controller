/*
 * brunch.js: Simple utilities for working with brunch.
 *
 */

var spawn = require('child_process').spawn,
    fs = require('fs'),
    haibu = require('../../haibu');


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
	    			callback("error in brunch");
	    		} else {
	    			brunch = spawn('brunch', ['build']);
	    			brunch.on('close', function(code) {
	    				if (code != 0) {
	    					callback("error in brunch");
	    				}
	    			});
	    		}
	    	});
			haibu.emit('brunch:build:success', 'silly');
		}
	}
}


