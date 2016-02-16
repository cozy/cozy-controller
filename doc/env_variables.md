ENV variables
=============

Cozy-Controller uses some env variables:

- `HOST` and `PORT` to set on which interface and port cozy-controller listen
- `NODE_ENV` to set the environment
  - development is used when hacking (some security checks are disabled)
  - test is used for running unit tests
  - production is used when you care about the data
- `COUCH_HOST` and `COUCH_PORT` are used if CouchDB is not listening on
  localhost:5984
- `COUCH_LOCAL_CONFIG` can indicate the config file for CouchDB if it's not in
  the default place (it's used to compute disk space occupied by CouchDB)
- `DB_NAME` is the name of the database (`cozy` by default)
- `BIND_IP_PROXY` can be used is you want the proxy to listen on something
  else than localhost
- `USE_SYSLOG`, `SYSLOG_HOST` and `SYSLOG_PORT` if you prefer to use syslog
  over simple log files in `/usr/local/var/log/cozy`.
