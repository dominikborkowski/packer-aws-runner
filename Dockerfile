# Build goss with glibc system
FROM golang:1.13 AS build_glibc_bins
ARG GOSS_VER=0.3.9
ENV GO111MODULE=on
RUN go get github.com/aelsabbahy/goss/cmd/goss@v${GOSS_VER} && \
    strip ${GOPATH}/bin/* && \
    go clean -cache -modcache

# Build goss, packer, and packer-provisioner-goss with musl
FROM golang:1.13-alpine3.10 as build_musl_bins
ARG PACKER_VER=1.5.1
ARG PACKER_PROVISIONER_GOSS_VER=1.0.0
ARG GOSS_VER=0.3.9
ENV GO111MODULE=on
RUN apk --no-cache --upgrade add binutils && \
    go get github.com/hashicorp/packer@v${PACKER_VER} && \
    go get github.com/YaleUniversity/packer-provisioner-goss@v${PACKER_PROVISIONER_GOSS_VER} && \
    go get github.com/aelsabbahy/goss/cmd/goss@v${GOSS_VER} && \
    strip $GOPATH/bin/* && \
    go clean -cache -modcache && \
    apk --no-cache del binutils

# Finally, put everything together in a new container

# Use latest Alpine Linux 3.10 as our base image,
#  since Alpine 3.11 uses python 3.8, which raises a SyntaxWarning with aws CLI
FROM alpine:3.10
LABEL maintainer="Dominik L. Borkowski"

# get binaries from musl based container
COPY --from=build_musl_bins \
    /go/bin/packer /go/bin/goss /go/bin/packer-provisioner-goss /bin/

# get binaries from glibc based container
COPY --from=build_glibc_bins \
    /go/bin/goss /bin/goss-glibc

# Install few essential tools and AWS CLI, then clean up
RUN apk --no-cache --upgrade add curl rsync jq \
    gcc python3 python3-dev musl-dev libffi-dev openssl-dev && \
    pip3 --no-cache-dir install --upgrade awscli aws-sam-cli && \
    apk --no-cache del python3-dev musl-dev libffi-dev openssl-dev linux-headers gcc && \
    rm -rf /var/cache/apk/* && \
    find / -type f -name "*.py[co]" -delete
