# Cloud Notes
This aplication acts as a cloud platform provisioning, deployment, and congiguration service.
It is mainly intended for Python Notebook execution and development. Use is primarily targeted
for developers and researchers who would like to get up and running in the cloud without previous
cloud provisioning knowledge or the time to learn the skills needed to setup a cloud environment.

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
1. Access to a web browser on the local machine. This is used to complete login steps associated with
   each platform as well as viewing the notebboks in the Jupyter server once it is deployed either
   locally or in the cloud.
2. An active subscription in one of the supported Cloud Platforms [below](#supported-platforms).

#### Linux
Install Docker using your distro's installation method. See Docker's provided installation
instructions for it's [supported platforms](https://docs.docker.com/install/#supported-platforms).

#### Windows
See the separate [Windows installation instructions](./docs/windows-setup.md), then install
Docker inside WSL following the Linux instructions above.

## Deployment

Simply run `cn` and provide the required arguments listed below. At any time to preview this
message, run `cn --help`

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
