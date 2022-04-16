# syntax=docker/dockerfile:1
FROM ubuntu:20.04
LABEL maintainer="Will Won <william.won@gatech.edu>"

# Install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt -y update
RUN apt -y install build-essential cmake git libboost-all-dev python3

# Copy files
WORKDIR /app
COPY . .

# Clone repo
RUN git clone --recursive https://github.com/astra-sim/astra-sim.git

WORKDIR /app/astra-sim
RUN git checkout willjwon/develop

WORKDIR /app/astra-sim/extern/network_backend/analytical
RUN git checkout develop

# Reset workdir
WORKDIR /app

