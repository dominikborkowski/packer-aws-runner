# packer-aws-runner

Basic CICD node for using Hashicorp's Packer as GitLab runner in AWS. To make it as slim as possible the binaries for software other than AWS CLI are copied from a set of other containers, created specifically for compiling those tools.

## What's included

* [Alpine Linux](https://alpinelinux.org/) 3.14
* [HashiCorp Packer](https://packer.io/) 1.8.10
* [Goss](https://github.com/aelsabbahy/goss/) 0.3.16
* [Packer Provisioner Goss](https://github.com/YaleUniversity/packer-provisioner-goss) 3.1.2
* [AWS CLI](https://aws.amazon.com/cli/) 1.22.57

### GOSS

There are two versions of GOSS included: musl (default) and glibc based one. Former can be used to run checks from the packer container, while the latter one can be copied into the target system with packer and executed there.

In addition, there is an ARM64 goss version compiled for ARM64 architecture, which can be used to test from inside targets running on that platform.

### Location of tools

* /bin/dgoss
* /bin/goss
* /bin/goss-glibc
* /bin/goss-glibc-arm64
* /bin/packer
* /bin/packer-provisioner-goss


## Additional tools

* bash
* curl
* git
* jq
* rsync


# Quick start

## With docker-compose

This should build the image, and drop you in a shell.

```
docker-compose run packer-aws-runner
```


## Without docker-compose

```
docker build --tag packer-aws-runner:1.7.10 .
docker run -it packer-aws-runner:1.7.10
```

# Building and publishing

Environment variable `TAG` controls the docker image tag, if omitted docker-compose will use `latest`.

To build a specific version, in addition to `latest`, you can run the following:

```
docker-compose build
docker-compose push
TAG='1.7.10' docker-compose build
TAG='1.7.10' docker-compose push
```

To build this image to run from a platform other than X86_64 (AMD64), specify it as such:

```
PLATFORM='linux/arm64' docker-compose build
PLATFORM='linux/arm64' docker-compose push
PLATFORM='linux/arm64' TAG='1.7.10' docker-compose build
PLATFORM='linux/arm64' TAG='1.7.10' docker-compose push
```

