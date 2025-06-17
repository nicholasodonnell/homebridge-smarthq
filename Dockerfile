FROM node:22-bookworm-slim AS base

# default environment variables
ENV \
  DEBIAN_FRONTEND=noninteractive

RUN \
  # add dependencies
  apt-get update \
  && apt-get install -y \
    ca-certificates \
    openssl \
    rsync \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  # create our own user and remove the node user
  && groupadd --gid 1001 app \
  && useradd --create-home --home /app --shell /bin/bash --gid 1001 --uid 1001 app \
  && userdel -r node \
  # install the latest version of npm
  && npm install -g npm@latest \
  # create the node_modules directory, make it owned by app user
  && mkdir -p /app/node_modules && chown app:app /app/node_modules \
  # create the global node_modules directory, make it owned by app user
  && mkdir -p /usr/local/lib/node_modules && chown app:app /usr/local/lib/node_modules \
  # update CA certificates
  && update-ca-certificates

USER app

WORKDIR /app

EXPOSE 3000

##############################

FROM base AS development

ENV NODE_ENV=development

COPY --chown=app:app package*.json ./

RUN npm ci --force \
  && npm cache clean --force

ENV PATH=/app/node_modules/.bin:$PATH

##############################

FROM development AS production

ENV NODE_ENV=production

COPY --chown=app:app . ./

RUN npm run build
