# use slim version of node on Debian buster for smaller image sizes
FROM node:16-buster-slim@sha256:ddb4d0ea63591c5a4ef6a9778e3913c3bfcc70328240bb4f97d31d4843587f9b as build

# python is used by some nodejs dependencies as an installation requirement
RUN apt-get update && \
    apt-get install -y \
    python3 \
    build-essential

WORKDIR /app

RUN cross-env REACT_APP_ENV=production yarn build-mainnet

# use slim version of node on Debian buster for smaller image sizes
FROM node:16-buster-slim@sha256:ddb4d0ea63591c5a4ef6a9778e3913c3bfcc70328240bb4f97d31d4843587f9b as runtime

# we use tini as process 1 to catch signals properly, which is also built into
# D<Plug>_ocker by default
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     tini \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

WORKDIR /app

# copy over the contents of node_modules etc
COPY --from=build /app/build .

ENTRYPOINT ["/usr/bin/tini", "--", "yarn", "hoprd"]
