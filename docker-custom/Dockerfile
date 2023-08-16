# ARG ARCH=amd64
ARG NODE_VERSION=18
ARG OS=alpine

#### Stage BASE ########################################################################################################
FROM node:${NODE_VERSION}-${OS} AS base

# Copy scripts
COPY scripts/*.sh /tmp/

# Install tools, create Node-RED app and data dir, add user and set rights
RUN set -ex && \
    apk add --no-cache \
        bash \
        tzdata \
        iputils \
        curl \
        nano \
        git \
        openssl \
        openssh-client \
        ca-certificates \
        eudev-dev \
        gcc \
        i2c-tools \
        musl-dev \
        py-pip \
        py3-pip \
        py3-smbus \
        py3-urwid \
        py3-wheel \
        python3 \
        python3-dev \
        wiringpi \
        wiringpi-dev && \
    mkdir -p /usr/src/node-red /data && mkdir -p /usr/share/doc/python-rpi.gpio && \
    deluser --remove-home node && \
    adduser -h /usr/src/node-red -D -H node-red -u 1000 && \
    chown -R node-red:root /data && chmod -R g+rwX /data && \
    chown -R node-red:root /usr/src/node-red && chmod -R g+rwX /usr/src/node-red
    # chown -R node-red:node-red /data && \
    # chown -R node-red:node-red /usr/src/node-red

# Set work directory
WORKDIR /usr/src/node-red

# Setup SSH known_hosts file
COPY known_hosts.sh .
RUN chmod +x ./known_hosts.sh \
    && ./known_hosts.sh /etc/ssh/ssh_known_hosts \
    && rm /usr/src/node-red/known_hosts.sh \
    && echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /etc/ssh/ssh_config

# package.json contains Node-RED NPM module and node dependencies
COPY package.json .
COPY flows.json /data
COPY scripts/entrypoint.sh .

#### Stage BUILD #######################################################################################################
FROM base AS build

# Install Build tools
RUN apk add --no-cache --virtual buildtools build-base linux-headers udev python3 && \
    npm install --unsafe-perm --no-update-notifier --no-audit --no-fund --only=production && \
    /tmp/remove_native_gpio.sh && \
    cp -R node_modules prod_node_modules

#### Stage RELEASE #####################################################################################################
FROM base AS RELEASE
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REF
ARG NODE_RED_VERSION
ARG ARCH
ARG TAG_SUFFIX=default

LABEL org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile=".docker/Dockerfile.alpine" \
    org.label-schema.license="Apache-2.0" \
    org.label-schema.name="Node-RED" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="Low-code programming for event-driven applications." \
    org.label-schema.url="https://nodered.org" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/node-red/node-red-docker" \
    org.label-schema.arch=${ARCH} \
    authors="Dave Conway-Jones, Nick O'Leary, James Thomas, Raymond Mouthaan"

COPY --from=build /usr/src/node-red/prod_node_modules ./node_modules

# Chown, install devtools & Clean up
RUN chown -R node-red:root /usr/src/node-red && \
    /tmp/install_devtools.sh && \
    rm -r /tmp/*

RUN npm config set cache /data/.npm --global

USER node-red

# Env variables
ENV NODE_RED_VERSION=$NODE_RED_VERSION \
    NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules \
    PATH=/usr/src/node-red/node_modules/.bin:${PATH} \
    FLOWS=flows.json

# ENV NODE_RED_ENABLE_SAFE_MODE=true    # Uncomment to enable safe start mode (flows not running)
ENV NODE_RED_ENABLE_PROJECTS=true

# Expose the listening port of node-red
EXPOSE 1880

# Add a healthcheck (default every 30 secs)
# HEALTHCHECK CMD curl http://localhost:1880/ || exit 1

# ENTRYPOINT ["npm", "start", "--cache", "/data/.npm", "--", "--userDir", "/data"]
ENTRYPOINT ["./entrypoint.sh"]