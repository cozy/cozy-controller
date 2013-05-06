/*
 * apps.js: Seed data for Application resource.
 *
 * (C) 2010, Nodejitsu Inc.
 *
 */

exports.apps = [
  {
     "resource": "App",
     "name": "test",
     "subdomain":"test",
     "state": "stopped",
     "maxDrones": 1,
     "drones": [],
     "directories": {
       "home": "hellonode"
     },
     "repository": {
       "type": "git",
       "url": "https://github.com/Marak/hellonode.git",
       "branch": "master"
     },
     "scripts": {
       "start": "server.js"
     }
  },
  {
     "resource": "App",
     "name": "chat",
     "subdomain":"test",
     "state": "stopped",
     "maxDrones": 1,
     "drones": [],
     "directories": {
       "home": "node-chat"
     },
     "repository": {
       "type": "git",
       "url": "https://github.com/scottgonzalez/node-chat.git",
       "branch": "master"
     },
     "scripts": {
       "start": "demo/chat.js"
     }
  },
  {
     "resource": "App",
     "name": "notes",
     "user": "notes",
     "subdomain":"test",
     "state": "stopped",
     "maxDrones": 1,
     "drones": [],
     "repository": {
       "type": "git",
       "url": "https://github.com/mycozycloud/cozy-notes.git",
       "branch": "master"
     },
     "scripts": {
       "start": "server.coffee"
     }
  },
  {
     "resource": "App",
     "name": "home",
     "user": "home",
     "subdomain":"test",
     "state": "stopped",
     "maxDrones": 1,
     "drones": [],
     "repository": {
       "type": "git",
       "url": "https://github.com/mycozycloud/cozy-home.git",
       "branch": "master"
     },
     "scripts": {
       "start": "server.coffee"
     }
  },
  {
     "resource": "App",
     "name": "data-system",
     "user": "data-system",
     "subdomain":"test",
     "state": "stopped",
     "maxDrones": 1,
     "drones": [],
     "repository": {
       "type": "git",
       "url": "https://github.com/mycozycloud/cozy-data-system.git",
       "branch": "master"
     },
     "scripts": {
       "start": "server.coffee"
     }
  }
];
