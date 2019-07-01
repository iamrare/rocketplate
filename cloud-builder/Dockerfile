FROM gcr.io/cloud-builders/gcloud

ENV TERRAFORM_VERSION=0.12.1
ENV TERRAFORM_VERSION_SHA256SUM=c9a30d3e3abf751b3b3e323897e9c7cb411d5c4bb7473a3284a2a2b4b89f93ed

RUN apt-get update && \
    apt-get -y install curl unzip ca-certificates && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      > terraform_linux_amd64.zip && \
    echo "${TERRAFORM_VERSION_SHA256SUM} terraform_linux_amd64.zip" > terraform_SHA256SUMS && \
    sha256sum -c terraform_SHA256SUMS --status && \
    unzip terraform_linux_amd64.zip -d /builder/terraform && \
    rm -f terraform_linux_amd64.zip && \
    apt-get remove --purge -y curl unzip && \
    apt-get --purge -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add docker command, from: https://github.com/GoogleCloudPlatform/cloud-builders/blob/master/docker/Dockerfile-18.09.6
RUN apt-get -y update && \
    apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        make \
        software-properties-common && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       xenial \
       edge" && \
    apt-get -y update && \
    apt-get -y install docker-ce=5:18.09.6~3-0~ubuntu-xenial

# Add docker-compose command, from: https://github.com/GoogleCloudPlatform/cloud-builders-community/blob/master/docker-compose/Dockerfile
RUN \
   apt -y update && \
   apt -y install ca-certificates curl && \
   curl -L "https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
   chmod +x /usr/local/bin/docker-compose

ENV PATH=/builder/terraform/:$PATH
COPY entrypoint.bash /builder/entrypoint.bash
ENTRYPOINT ["/builder/entrypoint.bash"]
