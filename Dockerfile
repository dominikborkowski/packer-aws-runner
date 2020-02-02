FROM hashicorp/packer:latest
LABEL maintainer "Dominik L. Borkowski"

# add basic tools we may need
RUN apk --no-cache --upgrade add \
    curl rsync

# install tools required to prepare aws CLI
RUN apk --no-cache --upgrade add \
    gcc python3 python3-dev musl-dev libffi-dev openssl-dev

# install aws CLI
RUN pip3 --no-cache-dir install --upgrade awscli aws-sam-cli

# strip packer to shave off 37.6MB out of 144.3MB
RUN strip /bin/packer

# remove development tools and clean up apk cache
RUN apk --no-cache del \
    python3-dev musl-dev libffi-dev openssl-dev && \
    rm -rf /var/cache/apk/*
