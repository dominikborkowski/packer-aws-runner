# Build goss with glibc system
FROM golang:1.17 AS build_glibc_bins
ARG GOSS_VER=0.3.16
ENV GO111MODULE=on
RUN go install github.com/aelsabbahy/goss/cmd/goss@v${GOSS_VER} && \
    strip ${GOPATH}/bin/* && \
    go clean -cache -modcache

# Build goss with glibc system - ARM64 edition
FROM --platform=linux/arm64 golang:1.17 AS build_glibc_bins_arm64
ARG GOSS_VER=0.3.16
ENV GO111MODULE=on
RUN go install github.com/aelsabbahy/goss/cmd/goss@v${GOSS_VER} && \
    strip ${GOPATH}/bin/* && \
    go clean -cache -modcache

# Build goss and packer-provisioner-goss with musl
FROM golang:1.17-alpine3.14 as build_musl_bins
ARG PACKER_PROVISIONER_GOSS_VER=3
ARG GOSS_VER=0.3.16
ENV GO111MODULE=on
RUN apk --no-cache --upgrade --virtual=build_environment add binutils git && \
    go install github.com/YaleUniversity/packer-provisioner-goss/v${PACKER_PROVISIONER_GOSS_VER}@latest && \
    go install github.com/aelsabbahy/goss/cmd/goss@v${GOSS_VER} && \
    strip $GOPATH/bin/* && \
    go clean -cache -modcache && \
    apk --no-cache del build_environment

# Finally, put everything together in a new container
FROM alpine:3.14
LABEL maintainer="Dominik L. Borkowski"
RUN apk --no-cache --upgrade add py3-pip

# Get binaries from musl based container
COPY --from=build_musl_bins \
    /go/bin/goss /go/bin/packer-provisioner-goss /bin/

# Get binaries from glibc based container
COPY --from=build_glibc_bins /go/bin/goss /bin/goss-glibc
COPY --from=build_glibc_bins_arm64 /go/bin/goss /bin/goss-glibc-arm64

# Get packer binaries from their official container
COPY --from=hashicorp/packer:1.8.0 /bin/packer /bin/packer

# Install few essential tools and AWS CLI, then clean up
RUN apk --no-cache --upgrade --virtual=build_environment add \
    gcc python3-dev musl-dev libffi-dev openssl-dev && \
    apk --no-cache --upgrade --virtual=random_tools add \
    bash curl git rsync jq python3 gomplate &&\
    pip3 --no-cache-dir install --upgrade awscli aws-sam-cli && \
    apk --no-cache del build_environment && \
    rm -rf /var/cache/apk/* && \
    find / -type f -name "*.py[co]" -delete

# install dgoss. it requires bash
RUN curl -L https://raw.githubusercontent.com/aelsabbahy/goss/master/extras/dgoss/dgoss -o /bin/dgoss && \
    chmod +x /bin/dgoss

# Install packer config and run its initialization, which will pull required modules
COPY config.pkr.hcl /root/
RUN packer init /root/config.pkr.hcl
