# packer-aws-runner

Basic CICD node for using Hashicorp's Packer as GitLab runner in AWS. To make it as slim as possible the binaries for software other than AWS CLI are copied from a set of other containers, created specifically for compiling those tools.

## What's included

* [Alpine Linux](https://alpinelinux.org/) 3.10
* [HashiCorp Packer](https://packer.io/) 1.5.4
* [Goss](https://github.com/aelsabbahy/goss/) 0.3.10
* [Packer Provisioner Goss](https://github.com/YaleUniversity/packer-provisioner-goss) 1.0.0
* [AWS CLI](https://aws.amazon.com/cli/) 1.17.9

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


