applications = require './applications'
disk = require './disk'

module.exports =

    'apps/:name/start':
        post: applications.start

    'apps/:name/install':
        post: applications.install

    # Old route
    'drones/:slug/start':
        post: applications.install

    'apps/:name/stop':
        post: applications.stop

    # Old route
    'drones/:slug/stop':
        post: applications.stop

    'apps/:name/update':
        post: applications.update

    # Old route
    'drones/:name/light-update':
        post: applications.update

    'apps/:name/uninstall':
            post: applications.uninstall

    # Old route
    'drones/:slug/clean':
        post: applications.uninstall

    'apps/all':
        get: applications.all

    'apps/started':
        get: applications.running
        
    # Old routes 
    'drones/running':
        get: applications.running
        
    'diskinfo':
        get: disk.info