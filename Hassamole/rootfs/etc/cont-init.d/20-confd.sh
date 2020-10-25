#!/usr/bin/with-contenv bashio
#shellcheck shell=bash

INGRESS_PORT=$(bashio::addon.ingress_port)
export INGRESS_PORT

mkdir -p /data/guacamole
confd -onetime -backend env
