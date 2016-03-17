Configuration
=============

It's possible to configure the cozy stack with the file
`/etc/cozy/controller.json`. It's a JSON file that looks like:

```json
{
  "dir_log": "/usr/local/var/log/cozy",
  "dir_source": "/usr/local/cozy/apps",
  "env": {
    "global": {
      "SECRET": "1234"
    },
    "home": {
      "DEBUG": "true"
    }
  }
}
```

It accepts the following options:

- `npm_registry`: you can fill it with the URL of a [private npm registry](https://docs.npmjs.com/misc/registry)
- `npm_strict_ssl`: a boolean to use `--strict-ssl` for npm commands
- `dir_app_log`: the directory where cozy applications logs are put
- `dir_app_bin`: the directory where cozy applications are installed
- `dir_app_data`: the directory where cozy apps can keep files that will be preserved after an update
- `file_token`: the file with the tokens for authentication of the apps
- `bind_ip_proxy`: you can bind the proxy on a public IP if you do not want to use a reverse proxy
- `restart_cmd`: the command that will be used to restart the cozy controller
- `env`: you can add some env variables to cozy apps. It's an object:
  - `global` will add this variables for all apps
  - else use the name of the application as the key.
