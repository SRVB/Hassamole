#!/usr/bin/with-contenv bashio
#shellcheck shell=bash

VERSION_FILE="/data/.guacamole-version-ext"
VERSION=$(if [ -e "${VERSION_FILE}" ]; then head -n 1 "${VERSION_FILE}"; else echo "${GUACAMOLE_VERSION}"; fi)

EXT_DIR="${GUACAMOLE_HOME}/extensions"
LIB_DIR="${GUACAMOLE_HOME}/lib"
mkdir -p "${EXT_DIR}"
mkdir -p "${LIB_DIR}"

declare -A EXTENSIONS=(
    ["guacamole-auth-jdbc"]=true
    ["guacamole-auth-quickconnect"]=config
)

for ext in "${!EXTENSIONS[@]}"; do
    if [ "${EXTENSIONS[$ext]}" == "config" ]; then
        EXTENSIONS[$ext]=$(bashio::config "extensions[\"${ext}\"]")
    fi
done

## Cleanup if a new version of guacamole is installed
if [ "${VERSION}" != "${GUACAMOLE_VERSION}" ]; then
    bashio::log.warning "It seems that you run a newer version of Guacamole, all extensions will reinstalled."
    rm -rf "${EXT_DIR:?}/"*
    echo "${GUACAMOLE_VERSION}" > "${VERSION_FILE}"
fi

declare -A EXTENSION_INSTALLER=(
    ["guacamole-auth-openid"]=false
    ["guacamole-auth-jdbc"]=true
    ["guacamole-auth-quickconnect"]=config
    ["guacamole-auth-totp"]=config
)

function installExtension()
{
    local ext=${1}
    local enabled=${2}

    # Default extension installer
    function defaultInstaller()
    {
        if [ ! -e "${EXT_DIR}/${ext}-${GUACAMOLE_VERSION}.jar" ] && [ "${enabled}" == true ]; then
            bashio::log.debug "Install ${ext}"
            curl -jksSL -o "/tmpfs/${ext}-${GUACAMOLE_VERSION}.tar.gz" "https://mirror.klaus-uwe.me/apache/guacamole/1.2.0/binary/${ext}-${GUACAMOLE_VERSION}.tar.gz"
            tar -C "${EXT_DIR}/" --strip-components 1 -zxf "/tmpfs/${ext}-${GUACAMOLE_VERSION}.tar.gz" "${ext}-${GUACAMOLE_VERSION}/${ext}-${GUACAMOLE_VERSION}.jar"
            rm -rf "/tmpfs/${ext}-${GUACAMOLE_VERSION}.tar.gz"
            bashio::log.notice "${ext} installed"
        elif [ -e "${EXT_DIR}/${ext}-${GUACAMOLE_VERSION}.jar" ] && [ "${enabled}" == false ]; then
            bashio::log.debug "Uninstall ${ext}"
            rm -rf "${EXT_DIR}/${ext}-${GUACAMOLE_VERSION}.jar"
            bashio::log.notice "${ext} uninstalled"
        else
            bashio::log.debug "${ext} is alredy installed or not enabled"
        fi
    }

    # Install the postgres extension
    function authjdbcInstaller()
    {
        if [ ! -e "${EXT_DIR}/${ext}-postgresql-${GUACAMOLE_VERSION}.jar" ] && [ "${enabled}" == true ]; then
            bashio::log.debug "Install ${ext}"
            curl -jksSL -o "/tmpfs/guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz" "https://mirror.klaus-uwe.me/apache/guacamole/1.2.0/binary/guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz"
            tar -C "${EXT_DIR}/" --strip-components 2 -zxf "/tmpfs/${ext}-${GUACAMOLE_VERSION}.tar.gz" "${ext}-${GUACAMOLE_VERSION}/postgresql/${ext}-postgresql-${GUACAMOLE_VERSION}.jar"
            tar -C "${EXT_DIR}/" --strip-components 2 -zxf "/tmpfs/${ext}-${GUACAMOLE_VERSION}.tar.gz" "${ext}-${GUACAMOLE_VERSION}/postgresql/schema"
            curl -jksSL -o "${LIB_DIR}/postgresql-${JDBC_DRIVER_VERSION}.jar" "https://jdbc.postgresql.org/download/postgresql-${JDBC_DRIVER_VERSION}.jar"
            rm -rf "/tmpfs/guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz"
            bashio::log.notice "${ext} installed"
        else
            bashio::log.debug "${ext} is alredy installed or not enabled"
        fi
    }

    # Custom installers
    declare -A EXTENSION_INSTALLER=(
        ["guacamole-auth-jdbc"]=authjdbcInstaller
    )

    # Choose the installer for this extension
    if [ ${EXTENSION_INSTALLER[$ext]+test} ]; then
        bashio::log.debug "Run installer for ${ext}"
        ${EXTENSION_INSTALLER[$ext]}
    else
        bashio::log.debug "Run default installer for ${ext}"
        defaultInstaller
    fi
}

for ext in "${!EXTENSIONS[@]}"; do
    installExtension "${ext}" "${EXTENSIONS[$ext]}"
done

echo "${GUACAMOLE_VERSION}" > "${VERSION_FILE}"
