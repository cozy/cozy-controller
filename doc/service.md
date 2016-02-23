What is a service?
==================

A service for Cozy is defined by these criteria:

1. It's some JavaScript code
2. That is embedded in Cozy-Data-System
3. As express/americano apps
4. And exposes an HTTP API (REST + JSON by default)
5. to offer functionalities to cozy applications.
6. This API follows the [JSON api specification](http://jsonapi.org/)
7. And [Cozy guidelines](https://cozy.github.io/cozy-guidelines/)
8. With URL prefixed by `/services/:service-name`.
9. It benefits from Cozy authentication and permissions
10. And workflows (code review, documentation, i18n).


Rationale
---------

### 1. It's some JavaScript code

JS is the lowest common denominator for all the code written at Cozy.
Technically, a service can be written in something else (CoffeeScript or
TypeScript) but it has to be compiled simply to JavaScript.

### 2. That is embedded in Cozy-Data-System

I can think to several services than can be useful: files, notifications,
applications management, sharing, settings, indexer/search, etc.
Running one node processus for each service will take a lot of RAM.
[Simple Cozy](https://github.com/cozy/simple-cozy) has shawn that it's
possible to run a nodejs processus with code from several git repository to
use less memory.

### 3. As express/americano apps

It's the simple way I see to make this happen.

### 4. And exposes an HTTP API (REST + JSON by default)

Idem. I don't see a reason to choose something more complicated for the
default. But it can be useful to have things that are not REST + JSON
(a service exposing a git-compatible API, so one can push-deploy to one's cozy
for example).

### 5. to offer functionalities to cozy applications.

Cozy applications can be run in the browser with cozysdk, on the server,
but there are also cozy-mobile and cozy-desktop. All of them should be able to
use the services even if the authentication mechanisms are not the same.

### 6. This API follows the [JSON api specification](http://jsonapi.org/)

I have nothing against [JSON-ld](http://json-ld.org/). The important is to
take one standard and stick to it. JSON api looks good. So, go for it!

### 7. And [Cozy guidelines](https://cozy.github.io/cozy-guidelines/)

It's the same rule than for other cozy projects.

### 8. With URL prefixed by `/services/:service-name`.

With each service is in its own namespace, we avoid conflicts.

### 9. It benefits from Cozy authentication and permissions

It's obvious that services should be benefit from the authentication
mechanisms used by Cozy-Proxy. For the permissions, it's more complicated.
Currently, they are used in cozy-data-system and are tied to the DocTypes in
CouchDB documents. I think we should generalize permissions.

For example, a service to send an email to the owner of the cozy instance can
be useful (think of Kresus sending you an email when your balance is too low).
This service will not manipulate CouchDB documents. But, even in absence of
doctypes, it should be possible to put a permission for this service.

### 10. And workflows (code review, i18n).

The services code run in the proxy. To avoid security issues, it's mandatory
that the Cozy team review the code from the services. From a UX point of view,
it's also important to manage i18n with the same workflow that we use
elsewhere to offer a coherent system.
