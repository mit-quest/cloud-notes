#!/bin/bash

__qi_container_name=$(curl \
    http://metadata.google.internal/computeMetadata/v1/instance/attributes/__qi_container_name \
    -H "Metadata-Flavor: Google")

__qi_application_bucket=$(curl \
    http://metadata.google.internal/computeMetadata/v1/instance/attributes/__qi_app_bucket \
    -H "Metadata-Flavor: Google")

echo "Copying data to /mnt/data."
mkdir -m 1777 /mnt/data
nohup gsutil -m cp -r gs://$__qi_application_bucket/* /mnt/data/ &>/dev/null &

echo "Checking for CUDA and installing."
_nvidia_dev_compute="developer.download.nvidia.com/compute"

# Check for CUDA and try to install.
if ! dpkg-query -W cuda-10-0; then
    _cuda_repo="cuda/repos/ubuntu1804/x86_64"
    _cuda_deb="cuda-repo-ubuntu1804_10.0.130-1_amd64.deb"

    curl -O "http://$_nvidia_dev_compute/$_cuda_repo/$_cuda_deb"
    dpkg -i "./$_cuda_deb"
    apt-key adv --fetch-keys "https://$_nvidia_dev_compute/$_cuda_repo/7fa2af80.pub"
    apt-get update

    apt-get install -y cuda-10-0
fi

echo "Checking for libcudnn7 and installing"
if ! dpkg-query -W libcudnn7; then
    _ml_repo="machine-learning/repos/ubuntu1804/x86_64"
    _ml_deb="nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb"
    curl -O "http://$_nvidia_dev_compute/$_ml_repo/$_ml_deb"
    apt install "./$_ml_deb"

    _cudnn_version"7.4.1.5-1+cuda10.0"
    apt-get update
    apt-get install --no-install-recommends -y \
        nvidia-driver-410 \
        libcudnn7=$_cudnn_version \
        libcudnn7-dev=$_cudnn_verison
fi

# Setup paths
export CUDA_HOME="/usr/local/cuda"
export PATH="${CUDA_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/compat:${LD_LIBRARY_PATH}"

# Enable persistence mode
nvidia-smi -pm 1

echo Checking for Docker and installing
# Check for docker and try to install it along with nvidia-docker2 to run
# Nvidia Container runtime.
if ! dpkg-query -W docker-ce; then
    apt-get update
    apt-get install -y \
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
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -sL https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -sL https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
        tee /etc/apt/sources.list.d/nvidia-docker.list

    apt-get update
    apt-get install -y nvidia-docker2
    pkill -SIGHUP dockerd

    gcloud auth print-access-token | docker login \
        -u oauth2accesstoken \
        --password-stdin \
        gcr.io

    nvidia-docker run \
        --runtime nvidia \
        --restart always \
        --mount type=bind,source=/mnt/data,target=/workspace/data \
        -p 8888:8888 \
        -d $__qi_container_name
fi
