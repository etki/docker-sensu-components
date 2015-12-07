#!/usr/bin/env bash

install-plugins() {
    echo "installing plugins: $@"
    for PLUGIN in "${@}"; do
        FULL_PLUGIN_NAME="sensu-plugins-$(echo -n $PLUGIN | sed s/sensu-plugins-//g)"
        echo "Installing plugin $FULL_PLUGIN_NAME"
        gem install $FULL_PLUGIN_NAME --no-ri --no-rdoc
        if [ "$?" -ne 0 ]; then
            echo "Failed to install plugin $FULL_PLUGIN_NAME"
            exit 1
        fi
    done
}

run-component() {

    SENSU_API_PORT=${SENSU_API_PORT:=80}
    SENSU_LOG_LEVEL=${SENSU_LOG_LEVEL:=info}
    SENSU_CONFIGURATION_DIRECTORY=${SENSU_CONFIGURATION_DIRECTORY:=/etc/sensu/conf.d}
    SENSU_CONFIGURATION_FILE=${SENSU_CONFIGURATION_FILE:=/etc/sensu/config.json}
    SENSU_TRANSPORT_NAME=${SENSU_TRANSPORT_NAME:=rabbitmq}
    SENSU_EXTENSIONS_DIRECTORY=${SENSU_EXTENSIONS_DIRECTORY:=/etc/sensu/extensions}

    export REDIS_URL=${SENSU_REDIS_URL:=$REDIS_URL}
    export RABBITMQ_URL=${SENSU_RABBITMQ_URL:=$RABBITMQ_URL}
    export PLUGINS_DIR=${SENSU_PLUGINS_DIRECTORY:=$PLUGINS_DIR}
    export HANDLERS_DIR=${SENSU_HANDLERS_DIRECTORY:=$HANDLERS_DIR}
    export USER=${SENSU_USER:=$USER}
    export SERVICE_MAX_WAIT=${SENSU_LAUNCH_TIMEOUT:=$SERVICE_MAX_WAIT}

    if [ ! -z "$SENSU_PLUGINS" ]; then
        install-plugins $SENSU_PLUGINS
    fi

    VERBOSITY_FLAG=""
    if [ ! -z "$SENSU_VERBOSE_LOGGING" ]; then
        VERBOSITY_FLAG="-v"
    fi

    exec sensu-$1 -L $SENSU_LOG_LEVEL -d $SENSU_CONFIGURATION_DIRECTORY \
        -e $SENSU_EXTENSIONS_DIRECTORY -c $SENSU_CONFIGURATION_FILE \
        $VERBOSITY_FLAG
}
case $1 in
"install-plugins")
    install-plugins "${@:2}"
;;
"run")
    if [ "server" != "$2" ] && [ "client" != "$2" ] && [ "api" != "$2" ]; then
        echo "Usage: $0 start (server|client|api)"
        exit 1
    fi
    run-component $2
;;
*)
echo "Usage:"
echo
echo "  Install plugins:"
echo "  $0 install-plugins (plugin list: ponymailer docker...)"
echo
echo "  Run specific component:"
echo "  $0 run (server|client|api)"
;;
esac