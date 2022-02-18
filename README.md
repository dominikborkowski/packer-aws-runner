# packer-aws-runner

Basic CICD node for using Hashicorp's Packer as GitLab runner in AWS. To make it as slim as possible the binaries for software other than AWS CLI are copied from a set of other containers, created specifically for compiling those tools.

## What's included

* [Alpine Linux](https://alpinelinux.org/) 3.14
* [HashiCorp Packer](https://packer.io/) 1.7.10
* [Goss](https://github.com/aelsabbahy/goss/) 0.3.16
* [Packer Provisioner Goss](https://github.com/YaleUniversity/packer-provisioner-goss) 3.1.2
* [AWS CLI](https://aws.amazon.com/cli/) 1.22.57

### GOSS

There are two versions of GOSS included: musl and glibc based one. Former can be used to run checks from the packer container, while the latter one can be copied into the target system with packer and executed there.

### Location of tools

* /bin/goss
* /bin/goss-glibc
* /bin/packer
* /bin/packer-provisioner-goss


## Additional tools

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
docker-compose push
TAG='1.7.10' docker-compose push
```
