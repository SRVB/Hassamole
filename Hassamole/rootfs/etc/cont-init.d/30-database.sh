#!/usr/bin/with-contenv bashio
#shellcheck shell=bash

VERSION_FILE="/data/.guacamole-version-db"
VERSION=$(if [ -e "$VERSION_FILE" ]; then head -n 1 "$VERSION_FILE"; else echo "${GUACAMOLE_VERSION}"; fi)

mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 0700 "$PGDATA"
mkdir -p /var/run/postgresql
chown postgres:postgres /var/run/postgresql

if [ -e "${PGDATA}/postgresql.conf" ]; then
    bashio::log.notice "Database already initialized"
else
    bashio::log.notice "Initialize database"
    s6-setuidgid postgres initdb > bashio::log.debug
fi

if [ ! -e "${VERSION_FILE}" ] || {
    [ -e "${VERSION_FILE}" ] && [ "${VERSION}" != "${GUACAMOLE_VERSION}" ]
}; then
    bashio::log.debug "Start postgres to setup the database"
    s6-setuidgid postgres pg_ctl -s -w -U postgres start > bashio::log.debug
    until pg_isready; do
        sleep 1
    done

    function databaseExists()
    {
        psql -lqt -U postgres | cut -d \| -f 1 | grep -wq "${DB_NAME}"
    }

    if ! databaseExists; then
        bashio::log.notice "Create database"
        createuser -U postgres "${DB_USER}"
        createdb -U postgres -O "${DB_USER}" "${DB_NAME}"
        for schema in "${GUACAMOLE_HOME}/extensions/schema/"*.sql; do
            psql -U "${DB_USER}" -d "${DB_NAME}" -f "${schema}" > bashio::log.debug
        done
    fi

    if databaseExists && [ "${VERSION}" != "${GUACAMOLE_VERSION}" ]; then
        bashio::log.warning "Upgrade database"
        psql -U postgres "${DB_USER}" -d "${DB_NAME}" -f "${GUACAMOLE_HOME}/extensions/schema/upgrade/upgrade-pre-${GUACAMOLE_VERSION}.sql" > bashio::log.debug
    fi
    s6-setuidgid postgres pg_ctl -s -w stop > bashio::log.debug
    echo "${GUACAMOLE_VERSION}" > "${VERSION_FILE}"
fi
