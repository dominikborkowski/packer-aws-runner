ARG GOSS_VER=0.4.4
ARG PACKER_PROVISIONER_GOSS_VER=3
ARG ALPINE_VERSION=3.18
ARG GOLANG_VERSION=1.22
ARG PACKER_VERSION=1.10.1


# Build goss with glibc system
FROM --platform=linux/arm64 golang:${GOLANG_VERSION} AS build_glibc_bins
ENV GO111MODULE=on
ARG GOSS_VER
# Build goss for FreeBSD - arm64 - currently doesn't build, not sure if go problem or goss
RUN GOOS=freebsd GOARCH=amd64 go install -ldflags "-X main.version=${GOSS_VER} -s -w" github.com/goss-org/goss/cmd/goss@v${GOSS_VER}
RUN GOOS=linux GOARCH=amd64 go install -ldflags "-X main.version=${GOSS_VER} -s -w" github.com/goss-org/goss/cmd/goss@v${GOSS_VER}
RUN GOOS=linux GOARCH=arm64 go install -ldflags "-X main.version=${GOSS_VER} -s -w" github.com/goss-org/goss/cmd/goss@v${GOSS_VER}
RUN go install -ldflags "-X main.version=${GOSS_VER} -s -w" github.com/goss-org/goss/cmd/goss@v${GOSS_VER} && \
    go clean -cache -modcache

# Build goss and packer-provisioner-goss with musl
FROM --platform=linux/arm64 golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} as build_musl_bins
ARG PACKER_PROVISIONER_GOSS_VER
ARG GOSS_VER
ENV GO111MODULE=on
ENV GOARCH=amd64
RUN apk --no-cache --upgrade --virtual=build_environment add binutils git && \
    go install github.com/YaleUniversity/packer-provisioner-goss/v${PACKER_PROVISIONER_GOSS_VER}@latest && \
    go install -ldflags "-X main.version=${GOSS_VER} -s -w"  github.com/goss-org/goss/cmd/goss@v${GOSS_VER} && \
    go clean -cache -modcache && \
    apk --no-cache del build_environment

# use upstream packer image
ARG PACKER_VERSION
FROM --platform=linux/amd64 hashicorp/packer:${PACKER_VERSION} as packer_upstream

# Finally, put everything together in a new container
FROM --platform=linux/amd64 alpine:${ALPINE_VERSION}
LABEL org.opencontainers.image.authors="dominik.borkowski@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/dominikborkowski/packer-aws-runner"
LABEL org.opencontainers.image.description="Hashicorp Packer packaged for GitLab runner in AWS"

RUN apk --no-cache --upgrade add py3-pip

# Get binaries from musl based container
COPY --from=build_musl_bins \
    /go/bin/linux_amd64/goss /go/bin/linux_amd64/packer-provisioner-goss /bin/

# Get binaries from glibc based container
COPY --from=build_glibc_bins /go/bin/goss /bin/goss-glibc-arm64
COPY --from=build_glibc_bins /go/bin/linux_amd64/goss /bin/goss-glibc
COPY --from=build_glibc_bins /go/bin/freebsd_amd64/goss /bin/goss-freebsd

# Get packer binaries from their official container
COPY --from=packer_upstream /bin/packer /bin/packer

# Install few essential tools and AWS CLI, then clean up
RUN apk --no-cache --upgrade --virtual=build_environment add \
    gcc python3-dev musl-dev libffi-dev openssl-dev && \
    apk --no-cache --upgrade --virtual=random_tools add \
    bash curl git gomplate jq netcat-openbsd python3 rsync &&\
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
