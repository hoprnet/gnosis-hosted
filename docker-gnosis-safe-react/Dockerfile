# use slim version of node on Debian buster for smaller image sizes
FROM node:16-buster-slim@sha256:ddb4d0ea63591c5a4ef6a9778e3913c3bfcc70328240bb4f97d31d4843587f9b as build

# python is used by some nodejs dependencies as an installation requirement
RUN apt-get update && \
    apt-get install -y \
    python3-dev \
    git \
    build-essential \
    libudev-dev

ADD safe-react /app

WORKDIR /app

ARG REACT_APP_NETWORK
ARG REACT_APP_IPFS_GATEWAY
ARG REACT_APP_SPENDING_LIMIT_MODULE_ADDRESS
ARG REACT_APP_SAFE_URL
ARG REACT_APP_CLIENT_GATEWAY_URL
ARG REACT_APP_TRANSACTION_SERVICE_URL

ENV REACT_APP_ENV production
ENV REACT_APP_APP_VERSION 99.0.0
ENV NODE_OPTIONS=--max-old-space-size=8192

RUN env
RUN yarn && yarn rescripts build

ENTRYPOINT ["/bin/bash"]
