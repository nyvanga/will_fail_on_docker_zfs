FROM httpd:2.4.63-bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN set -x && \
    apt-get update -qq && \
    apt-get dist-upgrade -qq --no-install-recommends
