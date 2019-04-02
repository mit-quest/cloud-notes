# Cloud Notes
This aplication acts as a cloud platform provisioning, deployment, and congiguration service.
It is mainly intended for Python Notebook execution and development intended for developers
and researchers to get up and running in the cloud without previous cloud provisioning knowledge
or the time to learn the skills needed to setup a cloud environment.

## Project Status
![Azure Pipelines Status](https://dev.azure.com/MITQuest/cloud-notes/_apis/build/status/Cloud%20Notes%20%28GCP%29?branchname=master)

## Scope
Cloud Notes aims to accomplish several tasks related to notebook execution and development.
1. Smiplify the cloud resource provisioning and deployments.
2. Provide a consistent runtime environment across public cloud providers.
3. Manage application dependencies.

Cloud Notes is not intended to provide fully customizable resource provisioning and deployments
or produce containers optimized for production serving. However, Cloud Notes is built on top of
tools such as Docker and has native support for further customization through a minimal templating
mechanism that utilizes dockerfiles.

## Getting Started
### Prerequisites
1. Access to a web browser on the local machine. This is used to complete login steps associated withe each platform as well as viewing the notebboks in the Jupyter server once it is deployed either locally or in the cloud.
2. An active subscription in one of the supported Cloud Platforms [below](#supported-platforms).

#### Linux
1. Install Docker using your distro's installation method. See Docker's provided installation instructions for it's [supported platforms](https://docs.docker.com/install/#supported-platforms).

#### Windows

**NOTE**:  
According to the official docker documentation, in order for Windows to work with docker,
The System _MUST_ meet the following specifications:

> - Windows 10 64bit: Pro, Enterprise or Education (1607 Anniversary Update, Build 14393 or later).
> - Virtualization is enabled in BIOS. Typically, virtualization is enabled by default.
>   This is different from having Hyper-V enabled. For more detail see Virtualization must
>   be enabled in Troubleshooting.
> - CPU SLAT-capable feature.
> - At least 4GB of RAM.

##### Manual Installation
1. Turn on optional features using the optional features tool here:  
   "C:\Windows\System32\OptionalFeatures.exe"

   Select the following features to enable:  
   a) Containers  
   b) Windows Subsystem for Linux  
   c) Hyper-V  

2. [Install Docker for Windows](https://docs.docker.com/docker-for-windows/install/).
3. Expose Docker daemon on tcp://localhost:2375
   ![Image of Docker Settings for TCP](./docs/_static/docker-tcp.png)
4. Give docker drive access
   ![Image of Docker Drive Share Settings](./docs/_static/docker-sharing.png)
5. Add a WSL configuration file `/etc/wsl.conf` to change the auto mount settings in WSL:

   ```
   [automount]
   root    = /
   options = "metadata"
   ```

##### Automated Install script
Provided in this repository is powershell script intended to install all the necessary components
for windows development called `win-setup.ps1`. To execute the script, run the following command
from the source directory. You willstill need to share the correct drives within docker desktop
and add a wsl.conf file in the wsl distribution.
```
Set-ExecutionPolicy Bypass -Scope Process -Force; iex (win-setup.ps1)
```

## Deployment

Simply run `cn` and provide the required arguments listed below. At any time to preview this message, run `cn --help`

```
usage: ./cn [options] workspace datasource provider
    --workspace,  -w  <WORKSPACE>  : The workspace to deploy to a cloud resource.
    --datasource, -d  <DATASOURCE> : A data source to deploy to a cloud resource.
    --provider,   -p  <PROVIDER>   : The cloud resource provider

    options:
    --help,       -h               : Print this help message.
    --name,       -n  <NAME>       : The base name of the application once deployed. If not set,
                      The name will be determined based on the provided workspace.
    --template,   -t  <TEMPLATE>   : A Dockerfile used to modify the default workspace environment.
                      This is a post-build step which will be applied after dependency management.
                      An example use case for templates is GPU support for the application within
                      workspace. A template will acquire the docker build context of the template's
                      location. A provided GPU teplate is provided for CUDA development support.
```

| <a name=supported-platforms></a>Cloud Platform    | Argument |          NOTES          |
|:--------------------------------------------------|:--------:|:------------------------|
| Local Jupyter Server                              | local    |                         |
| [Amazon Web Services](https://aws.amazon.com)     | aws      | *Currently unsupported* |
| [Google Cloud Platform](https://cloud.google.com) | gcp      |                         |
| [IBM Cloud](https://cloud.ibm.com)                | ibm      | *Currently unsupported* |
| [Microsoft Azure](https://azure.microsoft.com)    | az       | *Minimal Support*       |

---

### Notes

**__LOCAL__**: Any changes you make in the locally running container should be reflected on the local machine. You can also add more files to the workspace without the need to restart the container and the server should reflect those changes. Use this feature to ensure the container is capable of running the application before running the deploy.sh script to run the service in the cloud.

**__REMOTE__**: Getting the login key on from the server currently requires accessing the remote URL and then reading through the console output to find a string that indicates what the ogin token is. The token will appear in the following form `:8888/?token=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
