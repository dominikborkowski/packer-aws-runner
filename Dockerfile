# Build goss with glibc system
FROM golang:1.14 AS build_glibc_bins
ARG GOSS_VER=0.3.15
ENV GO111MODULE=on
RUN go get github.com/aelsabbahy/goss/cmd/goss@v${GOSS_VER} && \
    strip ${GOPATH}/bin/* && \
    go clean -cache -modcache

# Build goss and packer-provisioner-goss with musl
FROM golang:1.14-alpine3.11 as build_musl_bins
ARG PACKER_PROVISIONER_GOSS_VER=1.4.0
ARG GOSS_VER=0.3.15
ENV GO111MODULE=on
RUN apk --no-cache --upgrade --virtual=build_environment add binutils && \
    go get github.com/YaleUniversity/packer-provisioner-goss@v${PACKER_PROVISIONER_GOSS_VER} && \
    go get github.com/aelsabbahy/goss/cmd/goss@v${GOSS_VER} && \
    strip $GOPATH/bin/* && \
    go clean -cache -modcache && \
    apk --no-cache del build_environment

# Finally, put everything together in a new container
FROM alpine:3.11
LABEL maintainer="Dominik L. Borkowski"

# Get binaries from musl based container
COPY --from=build_musl_bins \
    /go/bin/goss /go/bin/packer-provisioner-goss /bin/

# Get binaries from glibc based container
COPY --from=build_glibc_bins \
    /go/bin/goss /bin/goss-glibc

# Get packer binaries from their official container
COPY --from=hashicorp/packer:1.6.6 /bin/packer /bin/packer

# Install few essential tools and AWS CLI, then clean up
RUN apk --no-cache --upgrade --virtual=build_environment add \
    gcc python3-dev musl-dev libffi-dev openssl-dev && \
    apk --no-cache --upgrade --virtual=random_tools add \
    curl git rsync jq python3 gomplate &&\
    pip3 --no-cache-dir install --upgrade awscli aws-sam-cli && \
    apk --no-cache del build_environment && \
    rm -rf /var/cache/apk/* && \
    find / -type f -name "*.py[co]" -delete
