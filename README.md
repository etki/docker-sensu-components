### Sensu unofficial Docker images

This repository provides Docker images of [Sensu][sensu] application.

#### What is Sensu?

[Sensu][sensu] is an application for all your monitoring needs. It provides
agent system which allows nodes to report arbitrary data about their condition
to master server, which passes data to handlers (e.g. email handler that sends
email to cluster owner if certain conditions are met) and which may be used by
GUI (most probably Uchiwa) to show that data in human-readable way. That vague
"data" term usually means hardware state - cpu checks, free ram, free space,
temperature - but, actually, that data may be nearly anything up to throughput
metrics and docker container count. The existence of handlers allows to perform
alerts in case sensu detects something bad - e.g. if web application turns out
to be inaccessible.

#### How do i use it?

Sensu consists of three building blocks - the server, which processes all the
checks and alerts, API, that provides access to server, and client, which is
intended to be run on a node and send data to server via transport. Besides
that, you'll need transport (RabbitMQ) and storage (Redis) for Sensu
interoperation, and, most probably, you'll need a GUI to visualize your cluster
state (see `uchiwa/uchiwa`).

To bring up your Sensu cluster, you'll need to run at least one copy of server
and API on your master node and a copy of client on every node. To do so, simply
run corresponding containers with appropriate settings.

    # master node
    
    docker run \
        -e SENSU_RABBITMQ_URL=amqp://guest:guest@amqp.example.com:5672/sensu \
        -e SENSU_REDIS_URL=redis://redis.example.com:6379 \
        -v $(pwd)/config/config.json:/etc/sensu/config.json \
        -v $(pwd)/config/conf.d:/etc/sensu/conf.d \
        -v $(pwd)/config/handlers:/etc/sensu/handlers \
        --name sensu-server \
        etki/sensu-server
    
    docker run \
        -e SENSU_RABBITMQ_URL=amqp://guest:guest@amqp.example.com:5672/sensu \
        -e SENSU_REDIS_URL=redis://redis.example.com:6379 \
        -v $(pwd)/config/config.json:/etc/sensu/config.json \
        -v $(pwd)/config/conf.d:/etc/sensu/conf.d \
        --name sensu-api \
        etki/sensu-api
    
    # client node

    docker run \
        -e SENSU_RABBITMQ_URL=amqp://guest:guest@amqp.example.com:5672/sensu \
        -e SENSU_REDIS_URL=redis://redis.example.com:6379 \
        -e SENSU_CLIENT_NAME=test-client \
        -e SENSU_CLIENT_SUBSCRIPTIONS=web,db \
        -v $(pwd)/config/config.json:/etc/sensu/config.json \
        -v $(pwd)/config/conf.d:/etc/sensu/conf.d
        --name sensu-client \
        etki/sensu-client

After that, client will run all the checks configured for `web` and `db`
subscriptions and push results to server.
Documentation for containers is stored in corresponding directories:
[server][server-readme], [client][client-readme], [api][api-readme].

#### Configuring checks, handlers and stuff

Regular Sensu (as opposed to Sensu Enterprise) supports only file-based
configuration, so you'll need to dance around the whole thing a little.
All the checks and handlers you configure should end up in `/etc/sensu/conf.d`
and `/etc/sensu/handlers` directories respectively. The easiest way to do so is
to supply them via docker volumes:

    docker run ...
        -v $(pwd)/server/config/conf.d:/etc/sensu/conf.d \
        -v $(pwd)/server/config/handlers:/etc/sensu/handlers \
        --name sensu-server \
        etki/sensu-server

After that whenever you need to apply renewed configuration you simply have to
restart corresponding container:

    nano server/config/conf.d/http-check.json
    docker restart sensu-server

\*To be honest, i haven't enough experience with Sensu and guess that handlers
may be declared in `conf.d` as well.

If you've done all of the above, you should have a running Sensu cluster. To
bring in the last part - visualization and proper GUI - you'll need Sensu
dashboard, which you may find in `uchiwa/uchiwa` image.

#### Stop, stop, i haven't understood a bit about checks and stuff

If you're new to the whole monitoring theme and don't understand what the heck
i'm talking about, you probably should visit [Sensu docs][sensu-docs] to get
familiar. I'm not going into detail on purpose to not mistranslate original
documentation and to evade the opportunity of stale documentation.

#### Common options for all images

| Option                          | Default value            | Note            |
|---------------------------------|--------------------------|-----------------|
| `SENSU_LOG_LEVEL`               | `info`                   |                 |
| `SENSU_AMQP_URL`                |                          | AMQP connection URL, e.g. `amqp://user:password@amqp:5672/sensu`. If this environmental variable is not set, canonical `RABBITMQ_URL` value will be used. |
| `SENSU_PLUGINS`                 |                          | Space-delimited list of plugins to install, e.g. `docker ponymailer`. |
| `SENSU_CONFIGURATION_DIRECTORY` | `/etc/sensu/conf.d`      | Directory for arbitrary configuration files, including checks. Normally you won't need to change this. |
| `SENSU_REDIS_URL`               |                          | REDIS connection URL, e.g. `redis://redis:6379`. If this environmental variable is not set, canonical `REDIS_URL` value will be used. |
| `SENSU_CONFIGURATION_FILE`      | `/etc/sensu/config.json` | Location of configuration file. Normally you won't need to change this. |
| `SENSU_EXTENSIONS_DIRECTORY`    | `/etc/sensu/extensions`  | Directory for Sensu extensions. Normally you won't need to change this. |
| `SENSU_TRANSPORT_NAME`          | `rabbitmq`               | Name of the transport to use, may be either `rabbitmq` or `redis`. |
| `SENSU_PLUGINS_DIRECTORY`       | `/etc/sensu/plugins`     | Directory for Sensu plugins. Normally you won't need to change this. |
| `SENSU_HANDLERS_DIRECTORY`      | `/etc/sensu/handlers`    | Directory for Sensu handlers. Normally you won't need to change this. |
| `SENSU_USER`                    | current user (root)      | System user to run Sensu. Normally you won't need to change this. |
| `SENSU_LAUNCH_TIMEOUT`          | `10`                     | Timeout (in seconds) for service to be launched. |

#### A small note on plugins

Most probably you'll need lots of plugins (this image tends to be as small as
possible and leaves the opportunity to tune it for you). You can install them in
two ways:

- By calling `docker-ctl.sh install-plugins plugin-name-a plugin-name-b`, more
on that later.
- By setting `SENSU_PLUGINS` environmental variable to the space-delimited list
of plugins, in that case install script will be called automaticaly before
service start. In current workflow that action takes place on every container
start, so it is more efficient to stick to first option (see "Building your own
Sensu").

In both cases, you may specify plugin names both with and without
`sensu-plugins-` prefix, so `docker ponymailer` would be effectively treated the
same as `sensu-plugins-docker` and `sensu-plugins-ponymailer`.

#### How do i visualize it?

You'll need a dashboard which is shipped separately from Sensu. See
`uchiwa/uchiwa` image for official distribution.

#### Scaling

Sensu doesn't provide docs for scaling (check [this][sensu-scaling] to see if
something has changed), but assuming from it's architecture, you may bring up as
many servers as you need and connect them via redis and rabbit mq clusters.

#### Internals

Sensu ships as a single solid bundle including API, server and client
components. Because of that, image `etki/sensu` already contains everything
needed to launch every component of Sensu; actually, derived images for every
component are simply exposing ports and calling `docker-ctl.sh` script added in
`etki/sensu`. So, technically you can load API component simply by changing
`etki/sensu` cmd: `docker run etki/sensu docker-ctl.sh run api`. The entrypoint
scripts in derived images exist only to add a hypothetical possibility of
tweaking anything before calling `docker-ctl.sh` script.

#### Building your own Sensu

Most probably you will need to tweak your Sensu installation (by adding
configuration and plugins), and while you should manage your configuration via
external volume, the best way to deal with plugins is to compile them in your
own derived image (external volume should work too, though). To do that, simply
add `RUN /opt/sensu/bin/docker-ctl.sh install-plugins %space-delimited list of plugins%`
directive to your Dockerfile, and the resulting image will contain all of your
plugins.

#### Contributing

Feel free to update github repo or to contact me about
missing/hard-to-understand documentation parts.

#### TODOs

- Move to busybox or alpine instead of centos to reduce image size. Everything
needed for work should be located in embedded folder (except for `.so`s).
- Better README for components, especially for base image

#### Licensing

* [Sensu][sensu-license] (MIT)
* You can do what you want with this repository contents. MIT license added
simply for formal consistency.

  [sensu]: https://sensuapp.org
  [sensu-docs]: https://sensuapp.org/docs/latest/
  [sensu-license]: https://github.com/sensu/sensu/blob/master/MIT-LICENSE.txt
  [sensu-scaling]: https://sensuapp.org/docs/latest/installation-summary#scaling-sensu
  [server-readme]: https://github.com/etki/docker-sensu/blob/master/server/README.md
  [client-readme]: https://github.com/etki/docker-sensu/blob/master/client/README.md
  [api-readme]: https://github.com/etki/docker-sensu/blob/master/api/README.md