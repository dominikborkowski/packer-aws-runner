# use latest alpine as our base image
FROM alpine:latest

# get packer binary out of hashicorp's image
COPY --from=hashicorp/packer:latest /bin/packer /bin/packer

# install few essential tools and AWS CLI, then clean up
RUN apk --no-cache --upgrade add curl rsync \
    gcc python3 python3-dev musl-dev libffi-dev openssl-dev && \
    pip3 --no-cache-dir install --upgrade awscli aws-sam-cli && \
    apk --no-cache del python3-dev musl-dev libffi-dev openssl-dev linux-headers && \
    rm -rf /var/cache/apk/* && \
    find / -type f -name "*.py[co]" -delete
