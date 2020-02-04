# Use latest Alpine Linux 3.10 as our base image,
#  since Alpine 3.11 uses python 3.8, which raises a SyntaxWarning with aws CLI
FROM alpine:3.10

# get packer binary out of HashiCorp's image
COPY --from=hashicorp/packer:latest /bin/packer /bin/packer

# get goss & dgoss from Ahmed Elsabbahy's image
COPY --from=aelsabbahy/goss:latest /goss/goss /goss/dgoss /bin/

# Install few essential tools and AWS CLI, then clean up
RUN apk --no-cache --upgrade add curl rsync jq \
    gcc python3 python3-dev musl-dev libffi-dev openssl-dev && \
    pip3 --no-cache-dir install --upgrade awscli aws-sam-cli && \
    apk --no-cache del python3-dev musl-dev libffi-dev openssl-dev linux-headers && \
    rm -rf /var/cache/apk/* && \
    find / -type f -name "*.py[co]" -delete
