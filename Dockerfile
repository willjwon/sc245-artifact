# syntax=docker/dockerfile:1
FROM ubuntu:20.04
LABEL maintainer="Will Won <william.won@gatech.edu>"

# Install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt -y update
RUN apt -y install build-essential git python3 python3-pip cmake zsh libboost-all-dev 

# Install Python dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Copy inputs
COPY optimizer_input optimizer_input

# Copy run scripts
COPY script .
RUN chmod +x *.sh
ENV PATH="/app:${PATH}"

# Clone ASTRA-sim and set branch
# RUN git clone --recursive --branch willjwon/develop \
#     https://github.com/astra-sim/astra-sim.git
# WORKDIR /app/astra-sim/extern/network_backend/analytical
# RUN git checkout develop

# Clone topology-bw-optimizer
WORKDIR /app
RUN git clone --branch sc22-artifact https://github.com/willjwon/topology-bw-optimizer.git
ENV PYTHONPATH=".:/app/topology-bw-optimizer:${PYTHONPATH}"

# Reset workdir
WORKDIR /app
