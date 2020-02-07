# Use latest Alpine Linux 3.10 as our base image,
#  since Alpine 3.11 uses python 3.8, which raises a SyntaxWarning with aws CLI
FROM alpine:3.10

LABEL maintainer="Dominik L. Borkowski"

# get binaries from build containers
COPY --from=dominikborkowski/build-packer-goss-provisioner:latest \
    /go/bin/packer /go/bin/goss /go/bin/packer-provisioner-goss /bin/

COPY --from=dominikborkowski/build-goss:latest /go/bin/goss /bin/

# Install few essential tools and AWS CLI, then clean up
RUN apk --no-cache --upgrade add curl rsync jq \
    gcc python3 python3-dev musl-dev libffi-dev openssl-dev && \
    pip3 --no-cache-dir install --upgrade awscli aws-sam-cli && \
    apk --no-cache del python3-dev musl-dev libffi-dev openssl-dev linux-headers && \
    rm -rf /var/cache/apk/* && \
    find / -type f -name "*.py[co]" -delete



