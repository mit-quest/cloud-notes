#!/bin/bash
echo "Checking for CUDA and installing."
# Check for CUDA and try to install.
if ! dpkg-query -W cuda-10-0; then
    curl \
        -O\
        http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb

    dpkg \
        -i ./cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
    apt-key \
        adv \
        --fetch-keys \
        https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
    apt-get update
    apt-get install cuda-10-0 -y
fi

# Enable persistence mode
nvidia-smi -pm 1

# TODO:
# Install cudnn >= 7.0

echo Checking for Docker and installing
# Check for docker and try to install it along with nvidia-docker2 to run
# Nvidia Container runtime.
if ! dpkg-query -W docker-ce; then
    apt-get update
    apt-get install \
        apt-transport-https \
        ca-certificates \
        gnupg-agent \
        software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    apt-add-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"

    apt-get update
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io

    # Install Nvidia-Docker
    distribution=$(. /etc/os-releas;echo $ID$VERSION_ID)
    curl -sL https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -sL https://nvidia/github.io/nvidia-docker/$distribution/nvidia-docker.list | \
        tee /etc/apt/sources.list.d/nvidia-docker.list

    apt-get update
    apt-get install -y nvidia-docker2
    pkill -SIGHUP dockerd

    gcloud auth configure-docker
    gcloud auth print-access-token | docker login \
        -u oauth2accesstoken \
        --password-stdin \
        gcr.io

    docker pull <IMAGE>
    docker run \
        --restart always \
        -p 8888:8888 \
        --mount type=bind,source=/mnt/data,target=/data
        --runtime nvidia
fi
