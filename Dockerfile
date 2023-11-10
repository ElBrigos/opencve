FROM python:3.8-slim-buster as base

# Builder
FROM base as builder

ARG OPENCVE_REPOSITORY=https://github.com/elbrigos/opencve.git

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opencve

# Clonage de la branche master de votre fork
RUN git clone --depth 1 -b master "${OPENCVE_REPOSITORY}" .

WORKDIR /app

RUN python3 -m venv /app/venv

ENV PATH="/app/venv/bin:$PATH"

RUN python3 -m pip install --upgrade pip

RUN python3 -m pip install /opencve/

COPY run.sh .
RUN chmod +x run.sh

# OpenCVE Image
FROM base

ARG HTTP_PROXY
ARG HTTPS_PROXY

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY

LABEL name="opencve"
LABEL maintainer="dev@opencve.io"
LABEL url="${OPENCVE_REPOSITORY}"

RUN apt-get update && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/ /app/

# Copier run.sh du builder à l'image finale
COPY --from=builder /opencve/run.sh /app/
RUN chmod +x /app/run.sh

WORKDIR /app

ENV PATH="/app/venv/bin:$PATH"

ENV OPENCVE_HOME="/app"

ENTRYPOINT ["/app/run.sh"]
