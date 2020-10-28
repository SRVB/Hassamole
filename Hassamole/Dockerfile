ARG BUILD_FROM

FROM $BUILD_FROM

ENV LANG=C.UTF-8 \
JDBC_DRIVER_VERSION=42.2.18 \
GUACAMOLE_VERSION=1.2.0 \
TOMCAT_MAJOR=9 \
TOMCAT_VERSION=9.0.37 \
TOMCAT_HOME=/opt/tomcat \
CATALINA_HOME=/opt/tomcat \
GUACAMOLE_HOME=/data/guacamole \
PGDATA=/data/postgresql \
DB_NAME=guacamole \
DB_USER=guacamole

RUN apk add --update --no-cache --virtual .build-deps \
git \
make \
automake \
autoconf \
cmake \
gcc \
curl \
libtool \
build-base \
linux-headers \
bsd-compat-headers \
intltool \
musl-dev \
cairo-dev \
libjpeg-turbo-dev \
libpng-dev \
pango-dev \
libssh2-dev \
libvncserver-dev \
openssl-dev \
libvorbis-dev \
libwebp-dev \
libsndfile-dev \
pulseaudio-dev \
libusb-dev \
freerdp-dev \
libwebsockets-dev \
go && \
\
apk add --update --no-cache \
ttf-inconsolata \
cairo \
libjpeg-turbo \
libpng \
freerdp \
pango \
libssh2 \
libvncserver \
libwebsockets \
pulseaudio \
openssl \
libvorbis \
libwebp \
libsndfile \
openjdk8 \
postgresql \
postgresql-client

COPY rootfs /

## Install confd
RUN export GOPATH=/tmp/build/go && \
mkdir -p $GOPATH/src/github.com/kelseyhightower && \
git clone https://github.com/kelseyhightower/confd.git $GOPATH/src/github.com/kelseyhightower/confd && \
cd $GOPATH/src/github.com/kelseyhightower/confd && \
make && make install

## Install OSSP-UUID
RUN mkdir -p /tmp/build/ossp-uuid && \
cd /tmp/build/ossp-uuid && \
git clone "https://github.com/sean-/ossp-uuid.git" . && \
./configure && \
make && make install && \
ln -s /usr/local/lib/libuuid.so.16.0.22 /lib/libossp-uuid.so

## Install Guacamole server
RUN mkdir -p /tmp/build/guacd && \
cd /tmp/build/guacd && \
git clone --branch "$GUACAMOLE_VERSION" "https://github.com/apache/guacamole-server.git" . && \
autoreconf -i && autoconf && \
./configure && \
make && make install

## Install Tomcat
RUN mkdir -p /tmp/build/guacamole && \
cd /tmp/build/guacamole && \
curl -jksSL -o /tmp/build/guacamole/apache-tomcat.tar.gz "http://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" && \
tar -C /opt -zxvf apache-tomcat.tar.gz && \
mv "/opt/apache-tomcat-${TOMCAT_VERSION}" "${TOMCAT_HOME}" && \
rm -rf "${TOMCAT_HOME}/webapps/"/*/

## Download Guacamole client
RUN curl -jksSL -o "${CATALINA_HOME}/webapps/ROOT.war" "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war"

RUN apk del .build-deps && \
rm -Rf /tmp/build && \
rm -f /var/cache/apk/*
